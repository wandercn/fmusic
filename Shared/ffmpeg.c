//
//  ffmpeg.c
//  music (macOS)
//
//  Created by lsmiao on 2023/6/29.
//
const int LOG_LEVEL_DEBUG = 1;

#define LOG_HEAD __LINE__,__func__,__FILE__

#include "ffmpeg.h"
AVFormatContext * get_format_ctx(const char *url) {
    if (LOG_LEVEL_DEBUG) {
        av_log_set_level(AV_LOG_DEBUG);
    }
    AVFormatContext *fmt_ctx = NULL;
    AVDictionaryEntry *tag = NULL;
    
    
    int ret;
    if ((ret = avformat_open_input(&fmt_ctx, url, NULL, NULL)))
        return NULL;
    
    if ((ret = avformat_find_stream_info(fmt_ctx, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Cannot find stream information\n",LOG_HEAD);
        return NULL;
    }
    while ((tag = av_dict_get(fmt_ctx->metadata, "", tag, AV_DICT_IGNORE_SUFFIX)))
        printf("%s=%s\n", tag->key, tag->value);
    av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s Key: tag: %s = %s\n",LOG_HEAD,tag->key, tag->value);
    //    av_dump_format(fmt_ctx,0,0,0)
    
    return fmt_ctx;
}

AVPacket  get_cover_image(const char *url){
    if (LOG_LEVEL_DEBUG) {
        av_log_set_level(AV_LOG_DEBUG);
    }
    const AVCodec *dec;
    AVPacket * pkt = av_packet_alloc();
    AVFormatContext * fmt_ctx = avformat_alloc_context();
    int video_stream_index = -1;
    fmt_ctx = get_format_ctx(url);
    
    av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s file: %s fmt_ctx addr: %p\n",LOG_HEAD,url,fmt_ctx);
    
    video_stream_index = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, &dec, 0);
    
    if (video_stream_index < 0){
        av_log(NULL, AV_LOG_INFO, "[%d]<%s>%s file: %s 不存在内嵌专辑图片\n",LOG_HEAD,url);
        avformat_close_input(&fmt_ctx);
        return *pkt;
    }
    // 必须用clone方法，否则avformat_close_input(&fmt_ctx)，内存释放，无法返回数据。
    pkt = av_packet_clone(&fmt_ctx->streams[video_stream_index]->attached_pic);
    //    int i =0;
    //    for (i=0; i< pkt->size; i++){
    //        printf("%d",pkt->data[i]);
    //    }
    av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s pkt_size: %d\n",LOG_HEAD,pkt->size);
    av_log(NULL, AV_LOG_DEBUG,"[%d]<%s>%s pkt_data: %p\n",LOG_HEAD,pkt->data);
    avformat_close_input(&fmt_ctx);
    av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s ptk_addr: %p\n",LOG_HEAD,pkt);
    return *pkt;
}

