require 'helper'

class UserTest < Test::Unit::TestCase

  ACCEPTABLE_DELTA = 0.00001

  should "Track users activated before this month as a full month" do
    u = new_user(activated_at: Time.parse("2015-01-01"), active: true, rollover_active_duration: 0)
    Timecop.freeze(Date.parse("2015-03-01")) do
      assert_equal 1, u.active_proportion_of_month(Time.parse("2015-02-01"))
    end
  end

  should "Track users activated during this month as a partial month" do
    u = new_user(activated_at: Time.parse("2015-01-15"), active: true, rollover_active_duration: 0)
    Timecop.freeze(Date.parse("2015-02-01")) do
      assert_in_delta 17.0/31, u.active_proportion_of_month(Time.parse("2015-01-01")), ACCEPTABLE_DELTA # 15 days of 31 in jan 2015
    end
  end
  
  should "Track users with an optional custom time span passed in" do
    u =  new_user(activated_at: Time.parse("2015-01-01"), active: true, rollover_active_duration: 0)
    Timecop.freeze(Date.parse("2015-03-20")) do
       assert_equal 1, u.active_proportion_of_interval(Time.parse("2015-01-15"), Time.parse("2015-02-15"))
    end
  end

  should "Track users activated this month and deactivated this month as a partial month" do
    u = new_user(activated_at: Time.parse("2015-01-10"), active: true, rollover_active_duration: 0)
    Timecop.freeze(Date.parse("2015-01-15")) do
      u.deactivate!
    end
    Timecop.freeze(Date.parse("2015-02-01")) do
      assert_in_delta 5.0/31, u.active_proportion_of_month(Time.parse("2015-01-01")), ACCEPTABLE_DELTA # 15 days of 31 in jan 2015
    end
  end

  should "Track users activated before this month and deactivated this month as a partial month" do
    u = new_user(activated_at: Time.parse("2015-01-01"), active: true, rollover_active_duration: 0)
    Timecop.freeze(Date.parse("2015-02-15")) do
      u.deactivate!
    end
    Timecop.freeze(Date.parse("2015-03-01")) do
      assert_in_delta 14.0/28, u.active_proportion_of_month(Time.parse("2015-02-01")), ACCEPTABLE_DELTA
    end
  end

  should "Track users activated before this month, deactivated this month, and reactivated this month as a longer partial month" do
    u = new_user(activated_at: Time.parse("2015-01-01"), active: true, rollover_active_duration: 0)
    Timecop.freeze(Date.parse("2015-02-15")) do
      u.deactivate!
    end
    Timecop.freeze(Date.parse("2015-02-20")) do
      u.activate!
    end
    Timecop.freeze(Date.parse("2015-03-01")) do
      assert_in_delta (15.0+8)/28, u.active_proportion_of_month(Time.parse("2015-02-01")), ACCEPTABLE_DELTA
    end
  end

  def cycle_activation(u)
    Timecop.freeze(Date.parse("2015-02-05")) do
      u.deactivate!
    end
    Timecop.freeze(Date.parse("2015-02-10")) do
      u.activate!
    end
    Timecop.freeze(Date.parse("2015-02-15")) do
      u.deactivate!
    end
    Timecop.freeze(Date.parse("2015-02-20")) do
      u.activate!
    end
  end

  should "Track users activated before this month, deactivated and reactivated 2 times as an even longer partial month" do
    u = new_user(activated_at: Time.parse("2015-01-01"), active: true, rollover_active_duration: 0)
    cycle_activation(u)
    Timecop.freeze(Date.parse("2015-03-01")) do
      assert_in_delta (4.0+5+9)/28, u.active_proportion_of_month(Time.parse("2015-02-01")), ACCEPTABLE_DELTA
    end
  end

  should "Track users activated during this month, deactivated and reactivated 2 times correctly" do
    u = new_user(activated_at: Time.parse("2015-02-03"), active: true, rollover_active_duration: 0)
    cycle_activation(u)
    Timecop.freeze(Date.parse("2015-03-01")) do
      assert_in_delta (2.0+5+9)/28, u.active_proportion_of_month(Time.parse("2015-02-01")), ACCEPTABLE_DELTA
    end
  end

  should "Billing a user zeroes the rollover" do
    u = new_user(activated_at: Time.parse("2015-01-01"), active: true, rollover_active_duration: 0)
    Timecop.freeze(Date.parse('2015-01-15')) do
      u.deactivate!
    end
    assert u.rollover_active_duration > 0
    u.billed!
    assert_equal 0,  u.rollover_active_duration
  end

  should "Raises if you ask for an out of range month" do
    # We have no information about dates in months before activated_at
    u = new_user(activated_at: Time.parse("2015-02-01"), active: true, rollover_active_duration: 0)
    assert_raises StandardError do
      u.active_proportion_of_month(Time.parse("2015-01-01"))
    end
  end

  should "Raises if you ask for a month that isn't finished yet" do
    u = new_user(activated_at: Time.parse("2015-02-01"), active: true, rollover_active_duration: 0)
    Timecop.freeze(Date.parse('2015-02-15')) do
      assert_raises StandardError do
        u.active_proportion_of_month(Time.parse("2015-02-01"))
      end
    end
  end
end
