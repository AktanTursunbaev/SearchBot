# frozen_string_literal: true

require 'telegram/bot'
require 'sqlite3'

# Entry Class for Bot
class SearchBot
  def initialize
    database = SQLite3::Database.open 'search_bot.db'
    # database.execute 'CREATE TABLE user (telegram_id INTEGER, is_searching BOOLEAN);'
    # database.execute 'CREATE TABLE message (text VARCHAR(500));'
    Telegram::Bot::Client.run('1883443421:AAH64ANpgi75cY7nmb33JLMf_Nw92B9X8SM') do |bot|
      bot.listen do |message|
        user = database.execute "SELECT * FROM user WHERE telegram_id = #{message.from.id};"
        database.execute "INSERT INTO user VALUES (#{message.from.id}, 0);" if user.empty?
        user = (database.execute "SELECT * FROM user WHERE telegram_id = #{message.from.id};")[0]
        case message.text
        when '/start'
          bot.api.send_message(chat_id: message.chat.id,
                               text: 'Hello, this is Search Bot')
          bot.api.send_message(chat_id: message.chat.id,
                               text: 'You can send any messages to it that will be stored in database')
          bot.api.send_message(chat_id: message.chat.id,
                               text: 'Also, you can type "/search" to find messages using a tag that you give')
        when '/search'
          bot.api.send_message(chat_id: message.chat.id,
                               text: 'Please enter a tag that will be used to search messages')
          database.execute "UPDATE user SET is_searching = 1 WHERE telegram_id = #{message.from.id};"
        else
          if user[1] == 1
            results = database.execute "SELECT * FROM message WHERE text LIKE '%#{message.text}%';"
            if !results.empty?
              open('result.txt', 'w+') do |result_file|
                results.each do |result|
                  result_file << "#{result[0]}\n"
                end
              end
              bot.api.send_message(chat_id: message.chat.id,
                                   text: 'Here is the file with the results')
              bot.api.send_document(chat_id: message.chat.id,
                                    document: Faraday::UploadIO.new('result.txt', 'text/plain'))
            else
              bot.api.send_message(chat_id: message.chat.id,
                                   text: 'There are no messages matching your tag')
            end
            database.execute "UPDATE user SET is_searching = 0 WHERE telegram_id = #{message.from.id};"
            bot.api.send_message(chat_id: message.chat.id,
                                 text: 'You can continue sending messages that need to be stored')
          else
            database.execute "INSERT INTO message VALUES ('#{message.text}');"
            bot.api.send_message(chat_id: message.chat.id,
                                 text: 'Your message was saved successfully')
          end
        end
      end
    end
  end
end

SearchBot.new
