#require 'devise_user_metering/hooks/user_metering'
#
module Devise
  module Models
    module UserMetering
      
      # takes a time, returns the active interval in that time's month
      def active_proportion_of_month(time)
        active_proportion_of_interval(time.beginning_of_month, time.end_of_month)
      end
      
      # takes an interval start and interval end
      # returns a decimal between 0 and 1 that reflects the proportion of time in the given interval
      # that the user has been 'active'
      def active_proportion_of_interval(interval_start, interval_end)
        if interval_end > Time.now
          raise StandardError.new("You can't get meter data for partial intervals")
        end
        if usage_in_interval?(interval_start, interval_end)
          raise StandardError.new('No usage data retained for this period of time')
        end

        in_interval = ->(time) { (interval_start..interval_end).cover?(time) }
        if in_interval.call(self.activated_at) || in_interval.call(self.deactivated_at)
          if !active && self.deactivated_at < interval_start
            return 0
          end
          interval_duration = interval_end - interval_start
          remainder = self.active ? [interval_end - self.activated_at, 0].max : 0
          (remainder + self.rollover_active_duration) / interval_duration
        else
          self.active ? 1 : 0
        end 
      end

      #activates the user to indicate the start of metering
      def activate!
        self.activated_at = Time.new
        self.active = true
        self.save!
      end

      #deactivates the user to indicate the end of metering
      def deactivate!
        now = Time.new
        self.deactivated_at = now
        self.active = false
        self.rollover_active_duration += now - [self.activated_at, now.beginning_of_month].max
        self.save!
      end

      #indicates the user has been accounted for said month/interval and resets the rollover_active_duration to zero
      def billed!
        self.rollover_active_duration = 0
        self.save!
      end

      private

      def usage_in_interval?(interval_start, interval_end)
        (self.deactivated_at && self.deactivated_at < interval_start) ||
          (self.activated_at && self.activated_at > interval_end)
      end   
    end
  end
end

