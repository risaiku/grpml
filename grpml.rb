#!/usr/local/bin/ruby
# coding: utf-8

#
# grptml.rb
# v1.0
#
# Copyright (c) 2015 risaiku
# This software is released under the MIT License.
#
# http://risaiku.net
# https://github.com/risaiku/grpml
#

require 'mail'
require 'set'
require 'yaml'

$yml = YAML.load_file(File.dirname(__FILE__) + '/grpml.yml')

OK_ADDRS           = $yml['ok_addrs']
ENVELOPE_FROM_ADDR = $yml['envelope_from_addr']
REPLY_TO_ADDR      = $yml['reply_to_addr']

SUBJECT_REPLACE_STR = '{subject}'
FROM_REPLACE_STR    = '{from_address}'
BODY_REPLACE_STR    = '{body}'

SUBJECT_TEXT = "[ML]#{SUBJECT_REPLACE_STR}"

RETURN_TEXT  = <<EOS
#{BODY_REPLACE_STR}
=-=-=-=-=-=-=-=-=-=-=
メーリングリストへ #{FROM_REPLACE_STR} さんからの投稿です。
返信はメーリングリスト全員への返信になるので注意して下さい。
EOS

def get_body(m) 
    if m.multipart? then
        if m.text_part then
            return m.text_part.decoded
        elsif m.html_part then
            return m.html_part.decoded
        end
    else
        return m.body.decoded.encode('UTF-8', m.charset)
    end

    return nil
end

def send_email(from, addr, subject, body)
    to_mail = Mail.new
    to_mail.from     = from
    to_mail.to       = addr
    to_mail.smtp_envelope_from = ENVELOPE_FROM_ADDR
    to_mail.reply_to = REPLY_TO_ADDR
    to_mail.subject  = subject
    to_mail.body     = body
    to_mail.charset  = 'utf-8'
    to_mail.delivery_method :sendmail
    to_mail.deliver
end

def send_mailing_list(from, subject, body)
    send_addrs = Set.new OK_ADDRS
    send_addrs.each{ |to_address|
        send_email(from, to_address, subject, body)
    }
end

mail = Mail.new(STDIN.read)

if OK_ADDRS.include?(mail.from.first) then
    sbj = mail.subject
    sbj   ||= ""
    subject = sbj.encode('UTF-8')
    body    = get_body(mail)

    if body then
        send_subject = SUBJECT_TEXT.sub(SUBJECT_REPLACE_STR, subject)
        send_text    = RETURN_TEXT.sub(BODY_REPLACE_STR, body).sub(FROM_REPLACE_STR, mail.from.first)
        send_mailing_list(mail.from.first, send_subject, send_text)
    end
end

