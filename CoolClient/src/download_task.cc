#define BOOST_DATE_TIME_NO_LIB 1
#include "download_task.h"
#include "job_info.h"
#include "client.pb.h"
#include "netpack.h"
#include "payload_type.h"
#include "verification.h"
#include "utilities.h"
#include <Poco/Logger.h>
#include <Poco/Format.h>
#include <Poco/Exception.h>
#include <Poco/Buffer.h>
#include <Poco/SharedMemory.h>
#include <Poco/Util/Application.h>
#include <Poco/Bugcheck.h>
#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>

using Poco::Logger;
using Poco::format;
using Poco::Exception;
using Poco::Buffer;
using Poco::SharedMemory;
using Poco::Util::Application;
using namespace ClientProto;

namespace CoolDown{
    namespace Client{

        DownloadTask::DownloadTask(const TorrentFileInfo& info, DownloadInfo& downloadInfo, 
                const string& clientid, const SockPtr& sock, int chunk_pos, HANDLE hFile)
        :Task(format("%s:%d", sock->peerAddress().host().toString(), chunk_pos)), 
         fileInfo_(info), 
         downloadInfo_(downloadInfo),
         clientid_(clientid), 
         sock_(sock), 
         chunk_pos_(chunk_pos), 
         check_sum_(fileInfo_.chunk_checksum(chunk_pos_)), 
         hFile_(hFile), 
         reported_(false){
        }

        string DownloadTask::fileid() const{
            return fileInfo_.fileid();
        }

        void DownloadTask::runTask(){
            Logger& logger_ = Application::instance().logger();
            poco_information(logger_, "Enter DownloadTask::runTask");
            UploadRequest req;
            req.set_clientid(clientid_);
            req.set_fileid(fileInfo_.fileid());
            req.set_chunknumber(chunk_pos_);


            NetPack pack( PAYLOAD_UPLOAD_REQUEST, req );
            retcode_t ret = pack.sendBy(*sock_);
            if( ERROR_OK != ret ){
                string msg( format("Error send upload request. ret : %d", (int)ret) );
                poco_notice(logger_, msg);
                throw Exception( msg );
            }
            ret = pack.receiveFrom(*sock_);
            if( ERROR_OK != ret ){
                string msg( format("Error recv upload reply. ret : %d", (int)ret) );
                poco_notice(logger_, msg);
                throw Exception( msg );
            }
            SharedPtr<UploadReply> reply = pack.message().cast<UploadReply>();
            if( reply.isNull() ){
                string msg( "Cannot cast recv message to UploadReply type." );
                poco_notice(logger_, msg);
                throw Exception( msg );
            }

            if( reply->returncode() != ERROR_OK ){
                string msg( format("remote client cannot handle upload request, returncode : %d", (int)reply->returncode()) );
                poco_notice(logger_, msg);
                throw Exception( msg );
            }

            //chunk_pos ranges from 0~chunk_count-1
            //bool isLastChunk = chunk_pos_ == ( fileInfo_.get_chunk_count() - 1 );
            poco_information(logger_, "Upload Message exchange succeed, now goto the real download.");
            int chunk_size = fileInfo_.chunk_size(chunk_pos_);
            poco_assert( chunk_size != -1 );
            poco_information_f2(logger_, "assert passed at file : %s, line : %d", string(__FILE__), static_cast<int>(__LINE__ - 1));

            int nRecv = 0;
            int nLeft = chunk_size;
            poco_information_f1(logger_, "Going to receive %d bytes.", chunk_size);
            Buffer<char> recvBuffer(chunk_size);

            while( nRecv < chunk_size){
                if( downloadInfo_.is_stopped){
                    throw Exception("DownloadTask is stopped by setting is_stoped.");
                }else if( downloadInfo_.is_job_removed ){
                    throw Exception("DownloadTask is stopped by setting is_job_removed.");
                }

                if( downloadInfo_.is_download_paused ){
					Poco::Thread::sleep(500);
					//throw Exception("DownloadTask is paused by setting is_download_paused.");
     //               poco_notice(logger_, "going to wait download_pause_cond in DownloadTask::runTask");
     //               ////FastMutex mutex;
     //               downloadInfo_.download_pause_cond.wait(downloadInfo_.download_pause_mutex);
					//poco_notice(logger_, "wake up by waiting download_pause_cond in DownloadTask::runTask");
                    continue;
                }
                if( downloadInfo_.bytes_download_this_second > downloadInfo_.download_speed_limit ){
                    poco_notice(logger_, "going to wait download_speed_limit_cond in DownloadTask::runTask");
                    FastMutex mutex;
                    downloadInfo_.download_speed_limit_cond.wait(mutex);
                    continue;
                }else{

                    int download_quota = downloadInfo_.download_speed_limit - downloadInfo_.bytes_download_this_second;
                    if( download_quota <= 0){
                        continue;
                    }

                    poco_information(logger_, "before receive contents from peer.");

                    int expect_bytes = download_quota > nLeft ? nLeft : download_quota;
					poco_information_f1(logger_, "Goint to receive %d bytes", expect_bytes);
                    int n = sock_->receiveBytes( static_cast<char*>(recvBuffer.begin()) + nRecv, expect_bytes);
                    poco_information_f1(logger_, "receive %d bytes from peer.", n);
                    if( n <= 0 ){
                        throw Exception("receiveBytes in DownloadTask::runTask return n <= 0");
                    }
                    downloadInfo_.bytes_download_this_second += n;
                    nRecv += n;
                    nLeft -= n;
                }
                poco_information_f2(logger_, "expcet %d bytes, %d bytes received!", chunk_size, nRecv);
            }
            string content(recvBuffer.begin(), recvBuffer.size());
            poco_assert(content.length() == chunk_size );
            poco_information_f2(logger_, "assert passed at file : %s, line : %d", string(__FILE__), static_cast<int>(__LINE__ - 1));
            poco_assert(nRecv == chunk_size );
            poco_information_f2(logger_, "assert passed at file : %s, line : %d", string(__FILE__), static_cast<int>(__LINE__ - 1));

            string content_check_sum( Verification::get_verification_code(content) );

            if( content_check_sum != check_sum_){
                throw Exception(format("verify failed, file : %s, offset : %Ld, original : %s, download_checksum : %s", 
                            fileInfo_.filename(), fileInfo_.chunk_offset(chunk_pos_), check_sum_, content_check_sum));
            }

			{
				using namespace boost::interprocess;
				uint64_t offset = fileInfo_.chunk_offset(chunk_pos_);
				LARGE_INTEGER file_offset;
				file_offset.QuadPart = offset;
				OVERLAPPED overlapped;
				memset(&overlapped, 0, sizeof(OVERLAPPED));
				overlapped.Offset = file_offset.LowPart;
				overlapped.OffsetHigh = file_offset.HighPart;
				DWORD nWrite;
				WriteFile(hFile_, content.data(), content.length(), &nWrite, &overlapped);
				/*
				file_mapping m_file( UTF82GBK(file_.path()).c_str(), read_write);
				mapped_region region(m_file, read_write, offset, chunk_size);
				int ret = memcpy_s(region.get_address(), region.get_size(), content.data(), content.length());
				if( ret != 0 ){
					poco_warning_f1(logger_, "memcpy_s returns %d.", ret);
				}
				//SharedMemory sm(file_, SharedMemory::AM_WRITE);
				////64bits problem???
				//memcpy(sm.begin() + fileInfo_.chunk_offset(chunk_pos_), content.data(), content.length() );
				*/

			}
			poco_information_f2(logger_, "Download task finished, file : %s, offset : %Lu",
							fileInfo_.filename(), fileInfo_.chunk_offset(chunk_pos_));
        }
    }
}
