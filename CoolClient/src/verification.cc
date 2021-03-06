#define BOOST_DATE_TIME_NO_LIB 1
#include "verification.h"
#include "utilities.h"
#include <cmath>
#include <Poco/SharedMemory.h>
#include <Poco/File.h>
#include <Poco/Bugcheck.h>
#include <Poco/Types.h>
#include <Poco/Buffer.h>
#include <Poco/Util/Application.h>
#include <boost/interprocess/file_mapping.hpp>
#include <boost/interprocess/mapped_region.hpp>

using Poco::DigestEngine;
using Poco::SharedMemory;
using Poco::File;
using Poco::Int64;

namespace CoolDown{
    namespace Client{

		MakeTorrentProgressObj::MakeTorrentProgressObj(make_torrent_progress_callback_t callback)
			:total_count_(0), current_count_(0), callback_(callback){

		}

		//if return false, means to stop the making progress
		bool MakeTorrentProgressObj::operator ()(){
			this->current_count_ += 1;
			if( callback_ ){
				return callback_(this->current_count_, this->total_count_);
			}else{
				return true;
			}
		}

		void MakeTorrentProgressObj::set_total_count(int total_count){
			this->total_count_ = total_count;
		}

        Verification::Verification(){
        }

        Verification::~Verification(){
        }

        FastMutex Verification::mutex_;
        SHA1Engine Verification::engine_;
		SHA1Engine Verification::file_engine_;

		int Verification::get_file_chunk_count(const File& file, int chunk_size){
			Int64 file_size = file.getSize();
			double piece_count = static_cast<double>(file_size) / chunk_size;
			int chunk_count = static_cast<int>( ceil(piece_count) );
			return chunk_count;
		}

		bool Verification::get_file_and_chunk_checksum_list(const File& file, int chunk_size,
			string* pFileChecksum, ChecksumList* pList, MakeTorrentProgressObj* pProgressObj){
			
			Poco::Logger& logger_ = Poco::Util::Application::instance().logger();
			poco_assert( chunk_size > 0 );
			poco_assert( pFileChecksum != NULL );
			poco_assert( pList != NULL );
			poco_assert( file.exists() );

			HANDLE hFile = 	CreateFileA( UTF82GBK(file.path()).c_str(),
				GENERIC_READ,
				FILE_SHARE_READ,
				NULL,
				OPEN_EXISTING,
				FILE_ATTRIBUTE_NORMAL,
				NULL
				);
			poco_assert( hFile != INVALID_HANDLE_VALUE );
			

			FastMutex::ScopedLock lock(mutex_);
			file_engine_.reset();
			//using namespace boost::interprocess;
			Int64 file_size = file.getSize();
			//string gbFilename(UTF82GBK(file.path()));
			//file_mapping m_file( gbFilename.c_str(), read_only);
			Int64 offset = 0;
			Poco::Buffer<char> buf(chunk_size);
			OVERLAPPED overlapped;
			memset(&overlapped, 0, sizeof(OVERLAPPED));
			while( offset + chunk_size < file_size ){
				LARGE_INTEGER file_offset;
				file_offset.QuadPart = offset;
				overlapped.Offset = file_offset.LowPart;
				overlapped.OffsetHigh = file_offset.HighPart;

				int rc = ReadFile(hFile, buf.begin(), buf.size(), NULL, &overlapped);
				poco_assert(rc != 0);
				//mapped_region region(m_file, read_only, offset, chunk_size);
				//char* start = static_cast<char*>( region.get_address() );
				char* start = buf.begin();
				pList->push_back(get_verification_code_without_lock(start, start + chunk_size) );
				file_engine_.update(start, chunk_size);

				if( pProgressObj ){
					bool continue_this_progress = (*pProgressObj)();
					if( continue_this_progress == false ){
						CloseHandle(hFile);
						return false;
					}
				}

				offset += chunk_size;
			}

			LARGE_INTEGER file_offset;
			file_offset.QuadPart = offset;
			overlapped.Offset = file_offset.LowPart;
			overlapped.OffsetHigh = file_offset.HighPart;

			int rc = ReadFile(hFile, buf.begin(), file_size - offset, NULL, &overlapped);
			poco_assert(rc != 0);
			char* last_chunk_start = buf.begin();

			pList->push_back(get_verification_code_without_lock(last_chunk_start, last_chunk_start + file_size - offset));
			file_engine_.update(last_chunk_start, file_size - offset);
			if( pProgressObj ){
				bool continue_this_progress = (*pProgressObj)();
				if( continue_this_progress == false ){
					CloseHandle(hFile);
					return false;
				}
			}
			pFileChecksum->assign(DigestEngine::digestToHex(file_engine_.digest()));
			CloseHandle(hFile);
			return true;
		}

        string Verification::get_verification_code(const char* begin, const char* end) {
            FastMutex::ScopedLock lock(mutex_);
            return Verification::get_verification_code_without_lock(begin, end);
        }
        string Verification::get_verification_code(const string& content){
            FastMutex::ScopedLock lock(mutex_);
            return Verification::get_verification_code_without_lock(content.data(), content.data()+content.length());
        }

        bool Verification::veritify(const char* begin, const char* end, const string& vc) {
            FastMutex::ScopedLock lock(mutex_);
            return vc == Verification::get_verification_code_without_lock(begin, end);
        }

        bool Verification::veritify(const string& source, const string& vc) {
            FastMutex::ScopedLock lock(mutex_);
            return vc == Verification::get_verification_code_without_lock(source.data(), source.data() + source.length());
        }

        string Verification::get_verification_code_without_lock(const char* begin, const char* end){
            poco_assert( end >= begin );
            engine_.reset();
            engine_.update(begin, end - begin);
            return DigestEngine::digestToHex(engine_.digest());
        }

        retcode_t Verification::calc_piece_verification_code(const char* begin, const char* end){
            if( end < begin ){
                return ERROR_VERIFY_INVALID_RANGE;
            }
            engine_.update(begin, end - begin);
            return ERROR_OK;
        }

    }
}
