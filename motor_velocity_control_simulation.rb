require "gosu"
require "gosu_more_drawables"

class Window < Gosu::Window
  def initialize(*args)
    super

    @motor = Motor.new(x: width / 2, y: height / 2)
  end

  def draw
    @motor.draw
  end

  def update
    @motor.update
  end
end

class Motor
  def initialize(x:, y:, target_velocity: 47)
    @x = x
    @y = y
    @target_velocity = target_velocity

    @ticks_per_revolution = 560.0
    @one_degree = 360.0 / @ticks_per_revolution
    @d = @ticks_per_revolution / 360.0
    @kp = 0.9

    @free_speed = ((6_000 / 20.0) / 60.0) * 28.0 # RPM

    @position = 0.0
    @last_position = 0.0
    @load = 0.0
    @power = 0.0
    @current = 0.0
    @stall_current = 8.5
    @new_target_velocity = @target_velocity

    @angle = 0.0

    @dt = Gosu.milliseconds - 16

    @s = ""
    @font = Gosu::Font.new(22, name: "NotoMono")
    @tea_time = Gosu.milliseconds
  end

  def draw
    Gosu.draw_rect(0, 0, 800, 600, 0xaa_252525)
    Gosu.draw_circle(@x, @y, 128, 64, 0xff_454545)
    Gosu.draw_circle(@x, @y, 100, 64, Gosu::Color::GRAY)
    Gosu.draw_circle(@x, @y, 16, 64, Gosu::Color::BLACK)

    Gosu.rotate(@angle, @x, @y) do
      Gosu.draw_rect(@x - 5, @y - 240, 10, 250, 0xff_008000)
    end

    @font.draw_text(@s.split(",").map { |s| s.strip.split(":").map(&:split).join(": ") }.join("\n"), 20, 20, 20)
  end

  def update
    t = (Gosu.milliseconds - @dt) * 0.001
    @angle = (@position * @one_degree) % 360.0

    @position += (@free_speed * @power) * (1.0 - @load)

    @velocity = (@position - @last_position).to_f
    @last_position = @position

    @power = (@new_target_velocity / @free_speed) * t
    @load += 0.025 * t
    @load %= 1.0
    # @load = 0.000

    error = @target_velocity - (@velocity / t)
    @new_target_velocity += error * @kp

    @current = @load * @stall_current

    if Gosu.milliseconds - @tea_time >= 100
      @tea_time = Gosu.milliseconds

      @s = format("TargetVelocity: %8.4f, Velocity: %8.4f, Velocity/s: %8.4f, NewTargetVelocity: %8.4f, Error: %8.4f, Pos: %8.4f, Angle: %8.4f, DeltaTime: %8.4f, 1-degree: %8.4f, D: %8.4f, Power: %8.4f, Load: %8.4f, Current*: %8.4f",
                  @target_velocity, @velocity, @velocity / t, @new_target_velocity, error, @position, @angle, t, @one_degree, @d, @power, @load, @current)
    end

    @dt = Gosu.milliseconds
  end
end

Window.new(800, 600).show
