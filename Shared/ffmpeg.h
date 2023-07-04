//
//  ffmpeg.h
//  music (macOS)
//
//  Created by lsmiao on 2023/6/29.
//

#ifndef ffmpeg_h
#define ffmpeg_h

#include <stdio.h>
#include "libavutil/avutil.h"
#include <libavformat/avformat.h>
#include <libavutil/dict.h>
AVFormatContext *  get_format_ctx(const char *url);
#endif /* ffmpeg_h */
