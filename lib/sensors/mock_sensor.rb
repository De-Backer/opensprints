#Mock: a sensor intended to mock the behavior of the basic_message arduino firmware. The behavior will always repeat: the first racer will go fast, the second slow, the third will go as fast as the first and the fourth will give up after 2 seconds.
class Sensor
  attr_accessor :r
  def initialize(filename=nil)
  end

  def version
    "mock-1"
  end

  def start
    @fast,@slow,@random = [[]]*3

    @start = Time.now+4.0
    @last_fast,@last_slow,@last_random = [Time.now+4.0]*3
    @t = Thread.new do
      loop do
        fake = fast
        Thread.current["racers"] = [fake, slow, fake, fake]
        Thread.current["time"] = (Time.now - @start)*1000
      end
    end
  end

  # I don't like this but it's just legacy until 
  # I truly deprecate the basic_msg
  def finish_times
    @t["racers"].map{|r| r[$RACE_DISTANCE / $ROLLER_CIRCUMFERENCE] }
  end

  def racers
    @t["racers"]
  end

  def time
    @t["time"]
  end

  def fast
    if Time.now-@last_fast>0.25
      @last_fast = Time.now
      @fast += [(@last_fast - @start)*1000] * 20
    end
    @fast
  end

  def slow
    if Time.now-@last_slow>0.25
      @last_slow = Time.now
      @slow += [(Time.now - @start)*1000] * 18
    end
    @slow
  end

  def random
    if Time.now-@last_random>0.25
      @last_random = Time.now
      @random += [(Time.now - @start)*1000] * random(20)+1
    end
    @random
  end

  def d_n_f
    if Time.now-@last_random>0.25 && Time.now-@start < 2.0
      @last_random = Time.now
      @random += [(Time.now - @start)*1000] * 20
    end
    @random
  end

  def false_start
  end

  def stop
    @t.kill
  end
end
