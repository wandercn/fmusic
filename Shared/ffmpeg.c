//
//  ffmpeg.c
//  music (macOS)
//
//  Created by lsmiao on 2023/6/29.
//

#include "ffmpeg.h"
AVFormatContext * get_format_ctx(const char *url) {
    AVFormatContext *fmt_ctx = NULL;
    AVDictionaryEntry *tag = NULL;
    
    
    int ret;
    if ((ret = avformat_open_input(&fmt_ctx, url, NULL, NULL)))
        return NULL;
    
    if ((ret = avformat_find_stream_info(fmt_ctx, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find stream information\n");
        return NULL;
    }
    while ((tag = av_dict_get(fmt_ctx->metadata, "", tag, AV_DICT_IGNORE_SUFFIX)))
        printf("%s=%s\n", tag->key, tag->value);
    //    av_dump_format(fmt_ctx,0,0,0)
    
    return fmt_ctx;
}

int get_cover_image(const char *url, AVPacket *pkt){
    const AVCodec *dec;
    AVFormatContext * fmt_ctx = avformat_alloc_context();
    static int video_stream_index = -1;
    fmt_ctx = get_format_ctx(url);
    
    video_stream_index = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, &dec, 0);
    
    if (video_stream_index < 0){
        printf("不存在");
        //    avformat_close_input(&fmt_ctx);
        return -1;
    }
    
    pkt->data = fmt_ctx->streams[video_stream_index]->attached_pic.data;
    pkt->size = fmt_ctx->streams[video_stream_index]->attached_pic.size;
    printf("i: %d\n",video_stream_index);
    
    printf("size: %d\n",pkt->size);
    printf("data: %s\n",pkt->data);
    avformat_close_input(&fmt_ctx);
    return 0;
}

