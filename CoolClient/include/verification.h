#ifndef VERIFICATION_H
#define VERIFICATION_H

#include "error_code.h"
#include <vector>
#include <string>
#include <Poco/Mutex.h>
#include <Poco/File.h>
#include <Poco/SHA1Engine.h>
#include <boost/function.hpp>
#include <boost/atomic.hpp>

using std::vector;
using std::string;
using Poco::FastMutex;
using Poco::File;
using Poco::SHA1Engine;
using boost::function;
using boost::atomic_bool;

namespace CoolDown{
    namespace Client{

		typedef function<bool(int, int)> make_torrent_progress_callback_t;

		struct MakeTorrentProgressObj{
			MakeTorrentProgressObj(make_torrent_progress_callback_t make_torrent_progress_callback_t);
			bool operator()();
			void set_total_count(int total_count);
		private:
			int total_count_;
			int current_count_;
			make_torrent_progress_callback_t callback_;
		};

        class Verification{
            public:
                typedef vector<string> ChecksumList;
				//typedef function<void()> make_torrent_progress_callback_t;
				static int get_file_chunk_count(const File& file, int chunk_size);
				static bool get_file_and_chunk_checksum_list(const File& file, int chunk_size,
					string* pFileChecksum, ChecksumList* pList, MakeTorrentProgressObj* pProgressObj = NULL);


                //static string get_file_verification_code(const string& fullpath) ;
                //static void get_file_checksum_list(const File& file, int chunk_size, ChecksumList* pList);
                static string get_verification_code(const string& content) ;
                static string get_verification_code(const char* begin, const char* end) ;
                static bool veritify(const char* begin, const char* end, const string& vc) ;
                static bool veritify(const string& source, const string& vc) ;

            private:
                static string get_verification_code_without_lock(const char* begin, const char* end);
                static retcode_t calc_piece_verification_code(const char* begin, const char* end);
                static FastMutex mutex_;
                static SHA1Engine engine_;
				static SHA1Engine file_engine_;			//used to calc file checksum when calc chunk checksum

                Verification();
                ~Verification();
        };
    }
}

#endif
