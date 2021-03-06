#include "upload_task.h"
#include "job_info.h"
#include "verification.h"
#include "utilities.h"
#include <Poco/Logger.h>
#include <Poco/Util/Application.h>
#include <Poco/SharedMemory.h>
#include <Poco/Format.h>
#include <Poco/Exception.h>
#include <Poco/Buffer.h>
#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>

using Poco::Logger;
using Poco::Util::Application;
using Poco::SharedMemory;
using Poco::format;
using Poco::Exception;

namespace CoolDown{
    namespace Client{

        UploadTask::UploadTask(DownloadInfo& downloadInfo, HANDLE hFile, UInt64 offset, int chunk_size, StreamSocket& sock)
        :Task( format("Upload task to %s", sock.peerAddress().host().toString()) ), 
        peerAddress_(sock.peerAddress().host().toString()),
        downloadInfo_(downloadInfo),
        hFile_(hFile),
        offset_(offset),
        chunk_size_(chunk_size),
        sock_(sock)
        {
            
        }
        UploadTask::~UploadTask(){

        }

        void UploadTask::runTask(){
            Logger& logger_ = Application::instance().logger();
            poco_information(logger_, "enter UploadTask::runTask");
            //string content;
			Poco::Buffer<char> content(chunk_size_);
            {
				OVERLAPPED overlapped;
				memset(&overlapped, 0, sizeof(overlapped));
				LARGE_INTEGER file_offset;
				file_offset.QuadPart = offset_;
				overlapped.Offset = file_offset.LowPart;
				overlapped.OffsetHigh = file_offset.HighPart;
				DWORD nRead;
				int rc = ReadFile(hFile_, content.begin(), content.size(), &nRead, &overlapped);
				if( rc == 0 ){
					throw Exception( format("ReadFile returns %d", rc) );
				}
				//using namespace boost::interprocess;
				//file_mapping m_file( UTF82GBK(file_->path()).c_str(), read_write);
				//mapped_region region(m_file, read_write, offset_, chunk_size_);
    //            /*SharedMemory sm(*file_, SharedMemory::AM_READ);
    //            content = string( sm.begin() + offset_, chunk_size_ );*/
				//content = string( (char*)region.get_address(), chunk_size_);
            }
			poco_information(logger_, "Got content by mapped_region.");
            poco_assert( content.size() == chunk_size_ );
            poco_information_f2(logger_, "going to send %d bytes to '%s'", chunk_size_, this->peerAddress_);
            int nSend = 0;
            while( nSend < chunk_size_ ){
                if( downloadInfo_.is_stopped){
                    throw Exception("UploadTask is stopped by setting is_stoped.");
                }else if ( downloadInfo_.is_job_removed ){
                    throw Exception("UploadTask is stopped by setting is_job_removed.");
                }
                int send_this_time = sock_.sendBytes( content.begin() + nSend , chunk_size_ - nSend);
                poco_information_f2( logger_, "in upload task, send %d bytes this time, %d bytes to send.", send_this_time, chunk_size_ - send_this_time );
                if( send_this_time <= 0 ){
                    poco_warning_f1(logger_, "bytes send this time is %d", send_this_time );
                    throw Exception("send bytes <= 0");
                }
                nSend += send_this_time;
                downloadInfo_.bytes_upload_this_second += send_this_time;
            }
            if( nSend != chunk_size_ ){
                throw Exception( format("%s, chunk_size is %d bytes but only send %d", name(), chunk_size_, nSend) );
            }

            string vc = Verification::get_verification_code(content.begin(), content.end() );
            poco_information_f3(logger_, "UploadTask succeed, \noffset : %Lu\nchunk_size : %d\nvc : %s", offset_, chunk_size_, vc);
            poco_information_f2(logger_, "send %d bytes to '%s' succeed.", nSend, peerAddress_);
        }
    }
}
