require 'base64'

# +SqlSessionStore+ is a stripped down, optimized for speed version of
# class +ActiveRecordStore+.

class SqlSessionStore < ActionController::Session::AbstractStore
  
  # The class to be used for creating, retrieving and updating sessions.
  # Defaults to SqlSessionStore::SqlSession, which is derived from +ActiveRecord::Base+.
  #
  # In order to achieve acceptable performance you should implement
  # your own session class, similar to the one provided for Myqsl.
  #
  # Only functions +find_session+, +create_session+,
  # +update_session+ and +destroy+ are required. The best implementations
  # are +postgresql_session.rb+ and +oracle_session.rb+.
  cattr_accessor :session_class
  self.session_class = SqlSession

  class Session
    class << self

      # Rack-ism for Rails 2.3.0
      SESSION_RECORD_KEY = 'rack.session.record'.freeze

      # For Rack compatibility (Rails 2.3.0+)
      def get_session(env, sid)
        sid ||= generate_sid
        session = session_class.find_session(sid)
        env[SESSION_RECORD_KEY] = session
        [sid, session.data]
      end

      # For Rack compatibility (Rails 2.3.0+)
      def set_session(env, sid, session_data)
        session = env[SESSION_RECORD_KEY]
        session.update_session(session_data)
      end
    end
  end

  # Below here is for pre-Rails 2.3.0 and not used in Rack-based servers
  #
  # Create a new SqlSessionStore instance.
  #
  # +session+ is the session for which this instance is being created.
  # +option+ is currently ignored as no options are recognized.

  def initialize(session, option=nil)
    if @session = session_class.find_session(session.session_id)
      @data = @session.data
    else
      @session = session_class.create_session(session.session_id)
      @data = {}
    end
  end

  # Update the database and disassociate the session object
  def close
    if @session
      @session.update_session(@data)
      @session = nil
    end
  end

  # Delete the current session, disassociate and destroy session object
  def delete
    if @session
      @session.destroy
      @session = nil
    end
  end

  # Restore session data from the session object
  def restore
    if @session
      @data = @session.data
    end
  end

  # Save session data in the session object
  def update
    if @session
      @session.update_session(@data)
    end
  end
  
  def id
    @session.id
  end
end

class CGI::Session
  def id
    @dbman.id
  end
end
__END__

# This software is released under the MIT license
#
# Copyright (c) 2008, 2009 Nate Wiger
# Copyright (c) 2005, 2006 Stefan Kaes

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

