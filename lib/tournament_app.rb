require 'lib/setup.rb'

Shoes.app(:title => TITLE, :width => 800, :height => 600) do
  extend RaceWindow
  extend Sorty

  def delete_racer(racer)
    image(20, 20, {:top => 8, :left => 350}) do
      delete_button
      click do
        @tournament.racers.delete(racer)
        @racer_list.clear { list_racers }
      end
    end
  end

  def delete_race(race)
    image(20, 20, {:top => 8, :left => 365}) do
      delete_button
      click do
        @tournament.matches.delete(race)
        @matches.clear { list_matches }
      end
    end
  end

  def add_to_race(racer)
    image(20, 20, {:top => 8, :left => 325}) do
      add_button
      click do
        @tournament.add_racer(racer)

        @matches.clear do
          list_matches
        end
      end
    end
  end

  def delete_button
    fill red
    rect(:top => 0, :left => 0, :height => 15, :width => 15)
    line(3,3,13,13)
    line(13,3,3,13)
  end

  def add_button
    fill red
    rect(:top => 0, :left => 0, :height => 15, :width => 15)
    line(8,3,8,13)
    line(3,8,13,8)
  end

  def redblue(race)
    image(20, 20, {:top => 8, :left => 340}) do
      fill eval($BIKES[0])
      rect(:top => 0, :left => 0, :height => 15, :width => 7)
      fill eval($BIKES[1])
      rect(:top => 0, :left => 7, :height => 15, :width => 7)
      click do
        case race.racers.length
        when 1: nil
        when 2:
          race.racers[0], race.racers[1] = race.racers[1], race.racers[0]
          @matches.clear {list_matches }
        else
          sort_names(race, $BIKES.map{|b| eval b}) { @matches.clear { list_matches }}
        end
      end
    end
  end

  background black
  file = Dir.glob("log/*").map{|file| [file, Time.parse(file.gsub(/.*(.{8}_.{6}).*/,'\1'))]}.sort_by{|e|e[1]}.last
  if file && file[1] > 1.day.ago
    @tournament = YAML::load_file(file[0])
  end

  @tournament ||= Tournament.new($RACE_DISTANCE)

  def list_racers
    resort_racers = lambda do |attribute| 
      @tournament.racers = @tournament.racers.sort_by {|r| attribute == :wins ? -r.send(attribute) : r.send(attribute)}
      relist_tournament
    end
    flow do
      flow(:width => 115) do
        para 'Name', :stroke => ivory
        click { resort_racers.call(:name) }
      end
      flow(:width => 50) do
        para 'Wins', :stroke => ivory
        click { resort_racers.call(:wins) }
      end
      flow(:width => 25) do
        para 'Best', :stroke => ivory
        click { resort_racers.call(:best_time) }
      end
    end

    @tournament.racers.compact.each do |racer|
      flow do
        border gray(0.65)
        flow(:width => 115) { para racer.name, :stroke => ivory }
        flow(:width => 50) { para racer.wins, " / ", racer.races, :stroke => ivory }
        flow(:width => 25) { para racer.best_time, "s", :stroke => ivory unless racer.best_time == Infinity }
        add_to_race racer
        delete_racer racer
      end
    end
    save_racers
  end

  def post_race
    relist_tournament
  end

  def tournament_record(race)
    race.winner
    @tournament.record(race)
    relist_tournament
  end

  def list_matches
    background gray(0.10), :curve => 14
    border gray(0.65), :curve => 14, :strokewidth => 3
    title "Matches", :stroke => ivory
    @tournament.matches.each do |match|
      flow(:margin => 5) do
        background gray(0.3)
        border black
        flow(:width => 270) do
          # FIXME THIS IS HORRENDOUS
          para((span(match.racers[0].name+" ", :stroke => eval($BIKES[0])) if match.racers[0]),
               (span(match.racers[1].name+" ", :stroke => eval($BIKES[1])) if match.racers[1]),
               (span(match.racers[2].name+" ", :stroke => eval($BIKES[2])) if match.racers[2]),
               (span(match.racers[3].name+" ", :stroke => eval($BIKES[3])) if match.racers[3]),
               :weight => "ultrabold")
        end
        button("race")do
          race_window match, @tournament
        end
        redblue(match)
        delete_race(match)
      end
    end
  end

  def add_racer(name)
    duped = @tournament.racers.compact.any? do |racer|
      racer.name == name
    end
    if !duped && name!='enter name'
      @tournament.racers << Racer.new(:name => name, :units => UNIT_SYSTEM)
      relist_tournament
    end
  end

  def relist_tournament
    @matches.clear {list_matches}
    @racer_list.clear {list_racers}
  end

  def save_racers(filename = nil)
    filename ||= "log/#{Time.now.strftime('%Y%m%d_%H%M%S')}-racers.yml"
    File.open(filename, 'w+') { |f| f << @tournament.to_yaml }
  end

  stack(:width => 380, :margin => 5, :curve => 14) do
    background gray(0.15), :curve => 14
    border gray(0.65), :curve => 14, :strokewidth => 3
    title "Racers", :stroke => ivory
    @racer_list = stack { list_racers }
    flow(:margin => 8) do
      @racer_name = edit_line "enter name", :width => 110
      button "+" do
        add_racer @racer_name.text
        @racer_name.text = ''
        @racer_name.focus
      end
    end
  end

  @matches = stack(:width => 800 - gutter() - 380, :margin => 5, :curve => 14) do
    list_matches
  end

  button "autofill matches" do
    @tournament.autofill_matches
    relist_tournament
  end

  button "open" do
    @tournament = YAML::load(File.open(@save_file = ask_open_file))
    relist_tournament
  end

  button "save" do
    save_racers(@save_file  = ask_open_file)
  end

  button "quicksave" do
    if @save_file
      save_racers(@save_file)
    else
      alert("No save location chosen yet.")
    end
  end
  
end
