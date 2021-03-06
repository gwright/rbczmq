/*
 *
 * Author:: Lourens Naudé
 * Homepage::  http://github.com/methodmissing/rbczmq
 * Date:: 20111213
 *
 *----------------------------------------------------------------------------
 *
 * Copyright (C) 2011 by Lourens Naudé. All Rights Reserved.
 * Email: lourens at methodmissing dot com
 *
 * (The MIT License)
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 *---------------------------------------------------------------------------
 *
 */

#ifndef RBCZMQ_LOOP_H
#define RBCZMQ_LOOP_H

#define ZMQ_LOOP_DESTROYED 0x01

typedef struct {
    zloop_t  *loop;
    int flags;
    Bool verbose;
    Bool running;
} zmq_loop_wrapper;

#define ZmqAssertLoop(obj) ZmqAssertType(obj, rb_cZmqLoop, "ZMQ::Loop")
#define ZmqGetLoop(obj) \
    zmq_loop_wrapper *loop = NULL; \
    ZmqAssertLoop(obj); \
    Data_Get_Struct(obj, zmq_loop_wrapper, loop); \
    if (!loop) rb_raise(rb_eTypeError, "uninitialized ZMQ loop!"); \
    if (loop->flags & ZMQ_LOOP_DESTROYED) rb_raise(rb_eZmqError, "object %p has been destroyed by the ZMQ framework", (void *)obj);

void _init_rb_czmq_loop();

#endif
