require 'lib/setup.rb'
require 'bacon'

describe 'A tournament' do
  before do
    @tournament = Tournament.new
  end

  it 'should have some racers' do
    3.times { @tournament.tournament_participations.build(:racer => Racer.new) }
    @tournament.racers.length.should==3
  end

  it 'should have some races' do
    @tournament.races = [Race.new, Race.new, Race.new]
    @tournament.races.length.should==3
  end

  it 'should have a name' do
    @tournament.name = "foo"
    @tournament.name.should == "foo"
  end

  describe 'unmatched_racers' do
    it 'should contain racers not in a match' do
      @tournament.save
      racers = ["Steve", "Joe"].map {|racer| Racer.create(:name => racer) }
      racers.each {|racer|
        @tournament.tournament_participations.create({:racer => racer})
      }
      @tournament.unmatched_racers.should ==(racers)
      sheila = Racer.create(:name => "Sheila")
      @tournament.autofill
      @tournament.tournament_participations.create({:racer => sheila})
      @tournament.unmatched_racers.should ==([sheila])
    end
  end
  describe 'autofill' do
    it 'should result in all the racers being matched' do
      @tournament = Tournament.new
      6.times do
        @tournament.tournament_participations.build({:racer => Racer.create})
      end
      @tournament.save
      @tournament.reload
      @tournament.races.length.should == 0
      @tournament.autofill
      @tournament.races.length.should == 3
      @tournament.save
    end

  end

end