--
-- PRANG! "port" to Minetest
--
-- Copyright 2021 by luk3yx
--

local DEFAULT_ZOOM = 0.7
if (PLATFORM == "Android" or PLATFORM == "iOS") and
        minetest.is_singleplayer() then
    DEFAULT_ZOOM = 0.4
end

local running_games = {}

local function dummy_func() end
local function class_helper(...)
    local cls = {init = dummy_func}
    for _, inherit in ipairs({...}) do
        for k, v in pairs(inherit) do
            cls[k] = v
        end
    end
    local cls_mt = {__index = cls}
    local function new(_, ...)
        local res = setmetatable({}, cls_mt)
        res:init(...)
        return res
    end
    setmetatable(cls, {__call = new})

    return cls
end

-- Make sure the server step is at most 33ms (~30FPS)
if not minetest.is_singleplayer() and
        tonumber(minetest.settings:get("dedicated_server_step")) > 0.033 then
    minetest.settings:set("dedicated_server_step", "0.033")
end

local Game, BaseObj, Player, Enemy, Food, PowerUp, ScoreThing, Animation
local GameOverScreen, Obstacle, TitleScreen

local zoom_levels = {}
local function set_game_zoom(pname, scale)
    zoom_levels[pname] = scale
    hud_fs.set_scale("prang:game_" .. pname, scale)
end

local function hide_sky(player, pname)
    player:set_clouds({density = 0})
    player:set_sky({clouds = false})
    player:set_sun({visible = false, sunrise_visible = false})
    player:set_moon({visible = false})
    player:set_stars({visible = false})

    -- Force the demo game to be completely redrawn to work around the
    -- lack of z-index in MT <5.2.0.
    local info = minetest.get_player_information(pname)
    if info and info.protocol_version < 39 then
        hud_fs.close_hud(player, "prang:game_" .. pname)
    end

    -- The background is 105% to cover any one pixel gaps
    hud_fs.show_hud(player, "prang:bg", {{
        hud_elem_type = "image",
        position = {x = 0.5, y = 0.5},
        scale = {x = -105, y = -105},
        text = "hud_fs_box.png^[colorize:#000",
    }})
end

minetest.register_on_joinplayer(function(player)
    player:set_physics_override({speed = 0, jump = 0, gravity = 0})
    player:set_pos({x = 0, y = 0, z = 0})
    player:hud_set_flags({
        hotbar = false,
        healthbar = false,
        crosshair = false,
        wielditem = false,
        breathbar = false,
        minimap = false,
        minimap_radar = false,
    })
    player:set_armor_groups({immortal = 1})
    player:set_properties({
        selectionbox = {0, 0, 0, 0, 0, 0},
        visual = "sprite",
        textures = {"hud_fs_box.png"},
        visual_size = {x = 0, y = 0, z = 0},
    })
    player:set_nametag_attributes({color = {r = 0, g = 0, b = 0, a = 0}})

    local pname = player:get_player_name()
    hide_sky(player, pname)
    set_game_zoom(pname, DEFAULT_ZOOM)
    running_games[pname] = TitleScreen(player)
end)

minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    running_games[pname].running = false
    running_games[pname] = nil
    set_game_zoom(pname, nil)
end)

minetest.register_globalstep(function(dtime)
    for _, game in pairs(running_games) do
        game:tick(dtime)
    end
end)

-- Formspecs
local TITLE_FS = [[
formspec_version[4]
size[15,15]
bgcolor[#000;neither]
box[0.3,13.3;4.4,1.6;#000]
button[1.8,14.2;0.6,0.6;zoom_out;-]
button[2.4,14.2;0.6,0.6;zoom_in;+]
button[0.4,13.5;4.1,0.6;toggle_sky;Toggle sky]
label[0.5,14.5;Zoom:]
label[0.3,13;Settings:]
button[3.2,14.2;1.3,0.6;reset_zoom;Reset]
image_button[5.4,7.7;4.2,0.87;prang_start_button.png;start;;false;false;]
image_button[2.385,8.8;10.23,0.87;prang_instructions_button.png;]] ..
    [[instructions;;false;false;]
image_button[4.54,9.9;5.92,0.87;prang_credits_button.png;credits;;false;false;]
image_button[5.835,11;3.33,0.87;prang_exit_button.png;exit;;false;false;]
label[5,14;If you accidentally close this menu\,
press your inventory key.]
]]

local INSTRUCTIONS_CREDITS_FS = [[
formspec_version[4]
size[15,15]
bgcolor[#000;neither]
image_button[5,14;5,0.87;prang_return_button.png;exit;;false;false;]
]]

local IN_GAME_FS = [[
formspec_version[4]
size[4,2.8]
label[0,0.5;]] .. minetest.colorize("yellow", "The game is not paused!") .. [[]
button_exit[0,1;4,0.8;ignore;Return to game]
button[0,2;4,0.8;exit;Quit game]
]]

local GAME_OVER_FS = [[
formspec_version[4]
size[15,15]
bgcolor[#000;neither]
hypertext[0,2.5;15,2;;<global valign=middle><tag name=bigger size=80>]] ..
    [[<center><bigger>Score: %s</bigger></center>]
image_button[5,10;5,0.87;prang_return_button.png;exit;;false;false;]
]]

-- Game code
Game = class_helper({
    running = true,
    time = 0,
    enemy_speed = 150,
})

local min, max = math.min, math.max
local function clamp(n, lower, upper)
    return min(max(n, lower), upper)
end

local function random_choice(list)
    return list[math.random(1, #list)]
end

function Game:init(player)
    self.name = player:get_player_name()
    self.player = Player(self)
    self.objects = {self.player}
    self.prepend_objects = {}
    if not self.title_screen then
        self.game_music_id = minetest.sound_play("prang_game", {
            to_player = self.name,
            loop = true,
        })
        self:every(0.5, self.on_timer)
    end
end

function Game:shutdown()
    self.running = false
    if self.game_music_id then minetest.sound_stop(self.game_music_id) end
    if self.sound_id then minetest.sound_stop(self.sound_id) end
    if running_games[self.name] == self then
        running_games[self.name] = nil
    end
end

function Game:set_music(sound, loop, reset_time)
    if self.sound_id then
        minetest.sound_stop(self.sound_id)
        if self.music_reset_timer then
            self.music_reset_timer:cancel()
            self.music_reset_timer = nil
        end
    end

    if sound == "game" then
        self.sound_id = nil
        minetest.sound_fade(self.game_music_id, 1000000, 1)
        return
    end
    -- Negative for compatibility with older MT clients
    minetest.sound_fade(self.game_music_id, -1000000, 0.001)

    self.sound_id = minetest.sound_play("prang_" .. sound, {
        to_player = self.name,
        loop = loop,
    })

    if reset_time then
        self.music_reset_timer = self:after(reset_time, self.set_music, "game",
            true)
    end
end

function Game:sound_play(sound)
    minetest.sound_play("prang_" .. sound, {to_player = self.name}, true)
end

function Game:after(delay, func, ...)
    return minetest.after(delay, function(...)
        if self.running then
            return func(self, ...)
        end
    end, ...)
end

function Game:every(interval, func, ...)
    self:after(interval, self.every, interval, func, ...)
    return func(self, ...)
end

function Game:get_mt_player()
    return self.running and minetest.get_player_by_name(self.name)
end

local function get_direction(speed, neg, pos)
    return speed * ((neg and -1 or 0) + (pos and 1 or 0))
end

-- These are used in both Game:tick() and for the instructions/credits screens
local game_size_elem = {type = 'size', w = 1920, h = 1080}
local game_box_elem = {type = 'box', x = 0, y = 0, w = 1920, h = 1080,
                       color = 'black'}

local sqrt_2 = math.sqrt(2)
function Game:tick(dtime)
    local mt_player = self:get_mt_player()
    if not mt_player then return end

    self.time = self.time + dtime

    local fs = {
        game_size_elem, game_box_elem,
        {type = 'label', x = 0, y = -10,
            label = 'FPS: ' .. math.floor(1 / dtime)}
    }

    if not self.title_screen then
        fs[4] = {type = 'label', x = 5, y = 16,
                 label = 'Score: ' .. self.player.score}
    end

    local controls = mt_player:get_player_control()
    for i = #self.objects, 1, -1 do
        local obj = self.objects[i]
        obj.moved = false
        obj:tick(self, dtime, controls)
    end

    for i = 1, self.player.lives do
        fs[#fs + 1] = {
            type = 'image',
            x = 1920 - i * 50, y = 15,
            w = 33, h = 33,
            texture_name = 'prang_character.png^[sheet:3x1:0,0'
        }
    end

    for i = #self.prepend_objects, 1, -1 do
        local obj = self.prepend_objects[i]
        table.insert(self.objects, 1, obj)
        self.prepend_objects[i] = nil
    end

    for i = #self.objects, 1, -1 do
        local obj = self.objects[i]
        fs[#fs + 1] = {
            type = 'image',
            x = obj.x, y = obj.y, w = obj.w, h = obj.h,
            texture_name = obj.texture or 'prang_logo.png',
        }
        -- obj.game = nil
        -- fs[#fs + 1] = {
        --     type = 'label',
        --     x = obj.x + obj.w, y = obj.y + obj.h,
        --     label = dump(obj)
        -- }
        -- obj.game = self
    end

    hud_fs.show_hud(mt_player, "prang:game_" .. self.name, fs)
end

function Game:count_objs_of_type(obj_type)
    local count = 0
    for _, obj in ipairs(self.objects) do
        if obj.type == obj_type then
            count = count + 1
        end
    end
    return count
end

local min_food_scores = {5000, 10000, 40000}
local min_enemy_scores = {5000, 15000, 40000}
local min_obstacle_scores = {5000, 15000, 30000}
local enemy_speed_scores = {15000, 30000}
local function get_min_count(score, min_scores)
    local n = 1
    for _, min_score in ipairs(min_scores) do
        if score < min_score then break end
        n = n + 1
    end
    return n
end

local enemies = {
    {
        sprite_id = 0,
        strategy = "move_straight",
        eats_food = true,
        noclip = true,
    },
    {
        sprite_id = 2,
        strategy = "move_random",
    },
    {
        sprite_id = 4,
        strategy = "follow_player",
        noclip = true,
    },
    {
        sprite_id = 6,
        strategy = "follow_player",
        eats_food = true,
        noclip = true,
        only_move_when_player_does = true,
    },
    {
        sprite_id = 8,
        strategy = "move_straight",
        eats_food = true,
    },
    {
        sprite_id = 10,
        strategy = "follow_player",
    },
}

Game.food_n = 0
function Game:on_timer()
    local score = self.player.score

    -- Check foods
    local min_foods = 5 - get_min_count(score, min_food_scores)
    if self:count_objs_of_type("food") < min_foods then
        local powerup = false
        if not self.powerup_exists then
            self.food_n = self.food_n + 1
            if self.food_n >= 5 then
                powerup = true
                self.powerup_exists = true
                self.food_n = 0
            end
        end
        if powerup then
            table.insert(self.prepend_objects, PowerUp(self))
        else
            table.insert(self.objects, Food(self))
        end
        self:sound_play("food_spawn")
    end

    if self:count_objs_of_type("enemy") <
            get_min_count(score, min_enemy_scores) then
        table.insert(self.objects, Enemy(self, random_choice(enemies)))
        self:sound_play("enemy_spawn")
    end

    if self:count_objs_of_type("obstacle") <
            get_min_count(score, min_obstacle_scores) then
        local obstacle = Obstacle(self)
        -- Don't place the obstacle if it's colliding with anything
        for _, obj in ipairs(self.objects) do
            if obstacle:collision_check(obj.x, obj.y, obj.w, obj.h) then
                obstacle = nil
                break
            end
        end
        if obstacle then
            table.insert(self.objects, obstacle)
        end
    end
end

function Game:respawn_everything()
    for _, obj in ipairs(self.objects) do
        obj:respawn()
    end
end

BaseObj = class_helper({
    w = 67, h = 67,
    collision = dummy_func,
    tick = dummy_func,
    respawn = dummy_func,
})

local spawn_places = {
    x = {{50, 504}, {680, 1240}, {1400, 1881}},
    y = {{200, 283}, {358, 713}, {863, 1040}},
}
local function randomly_place_obj(self)
    for _, dir in ipairs({"x", "y"}) do
        local bounds = random_choice(spawn_places[dir])
        self[dir] = math.random(bounds[1], bounds[2] - 70)
    end
end

function BaseObj:init(game)
    self.game = game
    if self.x == nil or self.y == nil then
        randomly_place_obj(self)
    end
end

function BaseObj:move(dx, dy)
    local old_x, old_y, w, h = self.x, self.y, self.w, self.h
    local x = clamp(old_x + dx, 0, 1920 - w)
    local y = clamp(old_y + dy, 0, 1080 - h)
    if x == old_x and y == old_y then return end

    local objects = self.game.objects
    for i = #objects, 1, -1 do
        local obj = objects[i]
        if self ~= obj and obj:collision_check(x, y, w, h) then
            if self:collision(obj) and obj:collision(self) then
                if obj:collision_check(x, old_y, w, h) then
                    x = old_x
                end
                if obj:collision_check(old_x, y, w, h) then
                    y = old_y
                end
            end
        end
    end

    self.x, self.y = x, y
    self.moved = true
end

function BaseObj:move_at_angle(angle, speed)
    self.angle = angle
    self:move(math.cos(angle) * speed, math.sin(angle) * speed)
end

function BaseObj:move_towards(target_x, target_y, speed)
    local x_dist = target_x - self.x
    local y_dist = target_y - self.y
    speed = clamp(math.sqrt(x_dist ^ 2 + y_dist ^ 2), -speed, speed)
    self:move_at_angle(math.atan2(y_dist, x_dist), speed)
end

-- function BaseObj.collision_check_old(obj1, obj2)
--     return (obj1.x + obj1.w > obj2.x and obj1.y + obj1.h > obj2.y and
--         obj2.x + obj2.w > obj1.x and obj2.y + obj2.h > obj1.y)
-- end

function BaseObj:collision_check(x, y, w, h)
    return (self.x + self.w > x and self.y + self.h > y and
        x + w > self.x and y + h > self.y)
end

function BaseObj:remove()
    local game = self.game
    for i, obj in ipairs(game.objects) do
        if self == obj then
            table.remove(game.objects, i)
            return
        end
    end
    error('Tried to remove non-existent object')
end

function BaseObj:explode()
    local game = self.game
    game:sound_play("enemy_death")
    table.insert(game.objects, Animation(game, "explosion", self.x, self.y, 5))
    self:remove()
end

function BaseObj:get_centre()
    return math.floor(self.x + self.w / 2), math.floor(self.y + self.h / 2)
end

local function ttl_tick(self, game, dtime)
    self.ttl = self.ttl - dtime
    local ok = self.ttl >= 0
    if not ok then self:remove() end
    return ok
end

-- Animations (explosions etc)
Animation = class_helper(BaseObj, {
    type = "animation",
})

local animation_frame_counts = {explosion = 3, vortex = 3, twinkle = 2}
function Animation:init(game, anim_name, x, y, fps, loop_count)
    self.game, self.x, self.y = game, x, y

    local frames = animation_frame_counts[anim_name]
    self.sheet, self.frames = "prang_" .. anim_name .. ".png", frames
    self.ttl = (loop_count or 1) * frames / fps
    self.fps = fps

    self:tick(game, 0)
end

function Animation:tick(game, dtime)
    if ttl_tick(self, game, dtime) then
        local frames = self.frames
        self.texture = self.sheet .. "^[sheet:" .. frames .. "x1:" ..
            -math.ceil(self.ttl * self.fps) % frames .. ",0"
    end
end

-- Player object
Player = class_helper(BaseObj, {
    type = "player",
    x = math.floor((1920 / 2) - (67 / 2) + 0.5),
    y = math.floor((1080 / 2) - (67 / 2) + 0.5),
    powerup_time = 0,
    death_time = 0,
    score = 0,
    extra_life_points = 0,
    lives = 3,
    alive = true,
})

function Player:respawn()
    self.x, self.y, self.alive = nil, nil, nil
end

function Player:collision()
    return true
end

function Player:tick(game, dtime, controls)
    if self.death_time > 0 then
        self.death_time = self.death_time - dtime
        self.texture = ("prang_character.png^[sheet:3x1:2,0^[opacity:" ..
                        math.floor(self.death_time * 255))
    else
        if not self.alive then
            game:respawn_everything()
        end
        self.texture = "prang_character.png^[sheet:3x1:0,0"
    end

    -- Get the player's speed
    local speed = dtime * 400
    if self.powerup_time > 0 then
        self.powerup_time = self.powerup_time - dtime
        speed = speed * (8/3)
    end

    local dx = get_direction(speed, controls.left, controls.right)
    local dy = get_direction(speed, controls.up, controls.down)
    if dx ~= 0 and dy ~= 0 then
        dx, dy = dx / sqrt_2, dy / sqrt_2
    end
    self:move(dx, dy)
end

function Player:has_powerup()
    return self.powerup_time > 0
end

function Player:add_score(score, item)
    local game = self.game
    self.score = self.score + score
    table.insert(game.prepend_objects, ScoreThing(game,
        score, item.x + (item.w - 67) / 2, item.y - item.h + 50))

    self.extra_life_points = self.extra_life_points + score
    if self.extra_life_points >= 5000 then
        self.extra_life_points = self.extra_life_points - 5000
        self.lives = min(self.lives + 1, 5)
    end

    local n = (get_min_count(self.score, enemy_speed_scores) + 4) / 10
    game.enemy_speed = 300 * n
end

function Player:reduce_lives()
    if self.lives < 1 then return end
    local game = self.game
    game:set_music("game")
    self.powerup_time = nil
    if self.lives == 1 then
        local p = game:get_mt_player()
        if p then
            local fs = GAME_OVER_FS:format(self.score)
            minetest.show_formspec(game.name, "prang:fs", fs)
            p:set_inventory_formspec(fs)
        end
        game.running = false
        table.insert(game.prepend_objects, 1, GameOverScreen())
        game:set_music("gameover")
        -- minetest.after(6.5, minetest.kick_player, game.name, "Game over!")
    else
        game:sound_play("player_death")
        self.death_time = 0.5
        self.alive = false
    end
    self.lives = self.lives - 1
end

GameOverScreen = class_helper(BaseObj, {
    x = 0, y = 0,
    w = 1920, h = 1080,
    texture = "prang_gameover.png",
})

ScoreThing = class_helper(BaseObj, {
    ttl = 1,
})

local score_sprites = {
    [20] = "1,0", [50] = "2,0", [100] = "0,1", [200] = "1,1", [500] = "2,1"
}
function ScoreThing:init(game, score, x, y)
    self.game = game
    self.texture_1 = "prang_digits.png^[sheet:3x2:" ..
        (score_sprites[score] or "0,0")
    self.texture = self.texture_1
    self.x, self.y = x, y
end

function ScoreThing:tick(game, dtime)
    if ttl_tick(self, game, dtime) then
        self.y = self.y - dtime * 200
        self.texture = (self.texture_1 .. "^[opacity:" ..
            math.floor(self.ttl * 255))
    end
end

Food = class_helper(BaseObj, {
    type = "food",
    ttl = 350 / 60,
})

local food_scores = {10, 50, 100, 200}
function Food:init(game)
    BaseObj.init(self, game)
    self.points = random_choice(food_scores)
    if self.points >= 100 then
        self.w = 53
    end
    self.texture = "prang_food_" .. self.points .. ".png"
end

function Food:collision(obj)
    if obj.type == "player" and obj.alive then
        self:remove()
        self.game:sound_play("player_eat")
        obj:add_score(self.points, self)
    elseif obj.type == "enemy" and obj.eats_food then
        self:remove()
    end
end

function Food:tick(game, dtime)
    if not ttl_tick(self, game, dtime) then
        table.insert(game.objects,
            Animation(game, "twinkle", self.x, self.y, 24, 2.5))
    end
end

PowerUp = class_helper(BaseObj, {
    type = "food",
    texture = "prang_powerup.png^[sheet:2x1:0,0",
    picked_up = false,
    ttl = Food.ttl,
})

function PowerUp:tick(game, dtime)
    if self.player then
        local p = self.player
        if not p:has_powerup() then
            self:remove()
            return
        end
        self.x = p.x + p.w / 2 + 6
        self.y = p.y - self.h + 8
        if p.powerup_time < 5 then
            self.texture = "prang_powerup.png^[sheet:2x1:1,0"
        end
    else
        Food.tick(self, game, dtime)
    end
end

function PowerUp:collision(obj)
    if not self.player and obj.type == "player" and obj.alive then
        self.game:set_music("powerup", false, 15)
        obj.powerup_time = 15
        self.player = obj

        -- Apparently follow_player enemies default to an angle of 20
        for _, enemy in ipairs(self.game.objects) do
            if enemy.type == "enemy" and
                    enemy.strategy == "follow_player" then
                enemy.angle = math.rad(20)
            end
        end
    end
end

function PowerUp:remove()
    self.game.powerup_exists = false
    BaseObj.remove(self)
end

Enemy = class_helper(BaseObj, {
    type = "enemy",
    strategy = "stay_still",
    sprite_id = 0,
    anim_timer = 0,
    base_texture = "prang_enemy.png^[sheet:12x1:",
    texture_modifier = "",
})

function Enemy:move(dx, dy)
    BaseObj.move(self, dx, dy)
    if dx < 0 then
        self.texture_modifier = "^[transformFX"
    else
        self.texture_modifier = ""
    end
end

local enemy_strategies = {}

function enemy_strategies:stay_still() end

function enemy_strategies:follow_player(speed)
    local p = self.game.player
    if p:has_powerup() then
        enemy_strategies.move_random(self, speed)
    else
        self:move_towards(p.x, p.y, speed)
    end
end

function enemy_strategies:move_straight(speed)
    if self.x == 0 then
        self.angle = 0
    elseif self.x >= 1920 - self.w then
        self.angle = -math.pi
    end
    self:move_at_angle(self.angle or math.rad(20), speed)
end

function Enemy:get_random_angle()
    local angle
    if self.y <= 30 + self.h then
        angle = math.rad(90 + math.random(-15, 15) * 3)
    elseif self.y >= 1080 - self.h then
        angle = math.rad(270 + math.random(-15, 15) * 3)
    elseif self.x == 0 then
        angle = math.rad(math.random(-9, 9) * 5)
    elseif self.x >= 1920 - self.w then
        angle = math.rad(180 + math.random(-9, 9) * 5)
    elseif self.angle then
        angle = self.angle
    else
        angle = math.rad(20)
    end
    return angle
end

function enemy_strategies:move_random(speed)
    self:move_at_angle(self:get_random_angle(), speed)
end

function Enemy:init(game, t)
    self.game = game
    for k, v in pairs(t) do
        self[k] = v
    end
    self:respawn()
    self.ttl = math.random(15, 25)
end

local enemy_x_pos = {40, 1820, 1820}
function Enemy:respawn()
    self.x = random_choice(enemy_x_pos)
    self.y = math.random(150, 1080 - 50)
    -- if self.x >= 1820 then
    --     self.texture_modifier = "^[transformFX"
    -- else
    --     self.texture_modifier = nil
    -- end
end

function Enemy:collision(obj)
    if obj.type == "player" and obj.alive then
        if obj:has_powerup() then
            self:explode()
            obj:add_score(500, self)
            return
        else
            obj:reduce_lives()
        end
    elseif obj.type == "obstacle" then
        if self.strategy == "move_straight" then
            if self.angle == 0 then
                self.angle = -math.pi
            else
                self.angle = 0
            end
        else
            self.angle = self:get_random_angle()
        end
        return true
    elseif obj.type == "food" then
        return self.eats_food
    end
end

function Enemy:tick(game, dtime)
    if not ttl_tick(self, game, dtime) then
        table.insert(game.objects,
            -- PRANG! runs this animation at 60FPS 3 times, however the server
            -- will likely not be running that fast.
            Animation(game, "vortex", self.x, self.y, 20))
        return
    end

    local sprite_id = self.sprite_id
    self.anim_timer = self.anim_timer + dtime
    if self.anim_timer > 0.25 then
        sprite_id = sprite_id + 1
        if self.anim_timer > 0.5 then
            self.anim_timer = 0
        end
    end
    self.texture = self.base_texture .. sprite_id .. ",0" ..
        self.texture_modifier

    if not self.only_move_when_player_does or game.player.moved then
        enemy_strategies[self.strategy](self, dtime * game.enemy_speed)
    end
end

Obstacle = class_helper(BaseObj, {
    type = "obstacle",
    x = 100, y = 100,
    w = 227, h = 67,
    texture = "prang_obstacle.png",
    tick = ttl_tick,
})

local obstacle_positions = {
    -- X       Y    Vert?  Left?
    {558.4,  757.6, false, true},
    {636.4,  255.5, false, false},
    {560.4,  255.5, true,  true},
    {1294.6, 339.5, true,  false},
}
function Obstacle:init(game)
    self.game = game
    local info = random_choice(obstacle_positions)

    self.x, self.y = info[1], info[2]
    if info[4] then
        self.texture = self.texture .. "^[transformFX"
    end
    if info[3] then
        self.w, self.h = self.h, self.w
        self.texture = self.texture .. "^[transformR90"
    end
    self.ttl = math.random(5, 15)
end

function Obstacle:collision(obj)
    if obj.type == "player" and obj:has_powerup() and obj.alive then
        obj:reduce_lives()
        return
    end
    return not obj.noclip
end

-- Title screen
local TitleScreenCharacter = class_helper(Enemy, {
    respawn = randomly_place_obj,
    noclip = true,
})

function TitleScreenCharacter:init(game, enemy_def)
    Enemy.init(self, game, enemy_def)
    self.strategy = "move_random"
    self.only_move_when_player_does = nil
    self.ttl = math.huge
end

local TitleScreenLogo = class_helper(BaseObj, {
    anim_timer = 0,
    frame = 0,
    x = 1920 / 2 - 1116 / 2, y = 320 - 223 / 2,
    w = 1116, h = 223,
})

function TitleScreenLogo:tick(game)
    self.texture = "prang_logo.png^[verticalframe:6:" ..
        math.floor((game.time * 10) % 6)
end

TitleScreen = class_helper(Game, {title_screen = true})

function TitleScreen:init(player)
    Game.init(self, player)

    self.game_music_id = minetest.sound_play("prang_title", {
        to_player = self.name,
        loop = true,
    })

    assert(#self.objects == 1)
    self.player.tick = dummy_func
    self.player.lives = -1
    self.objects[1] = TitleScreenLogo(self)
    local play_text = BaseObj(self)
    play_text.w = 270
    play_text.h = 70
    play_text.x = 1920 / 2 - play_text.w / 2
    play_text.y = 65
    play_text.texture = "prang_play.png"
    self.objects[2] = play_text
    self.objects[3] = TitleScreenCharacter(self, {
        anim_timer = -math.huge,
        base_texture = "prang_character.png^[sheet:3x1:",
        strategy = "move_random",
    })
    for i, enemy_def in ipairs(enemies) do
        self.objects[i + 3] = TitleScreenCharacter(self, enemy_def)
    end
    local obstacle = Obstacle(self)
    obstacle.ttl = math.huge
    self.objects[#self.objects + 1] = obstacle

    player:set_inventory_formspec(TITLE_FS)
    minetest.show_formspec(self.name, "prang:fs", TITLE_FS)
end

local function show_instructions_credits(player, pname, formname, img)
    -- Freeze the demo (but keep the music)
    running_games[pname].running = false
    hud_fs.show_hud(pname, "prang:game_" .. pname, {
        game_size_elem,
        game_box_elem,
        {type = "image", x = 0, y = 0, w = 1920, h = 1080, texture_name = img},
        {type = "image", x = 541.5, y = 24, w = 837, h = 152,
            texture_name = "prang_small.png"}
    })
    player:set_inventory_formspec(INSTRUCTIONS_CREDITS_FS)
    if formname ~= "" then
        minetest.show_formspec(pname, formname, INSTRUCTIONS_CREDITS_FS)
    end
end

hud_fs.set_z_index("prang:bg", -100)
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "" and formname ~= "prang:fs" then return end

    local pname = player:get_player_name()
    if not zoom_levels[pname] then return end

    if not running_games[pname].title_screen then
        -- In-game and the game over screen
        if fields.exit then
            running_games[pname]:shutdown()
            running_games[pname] = TitleScreen(player)
        elseif fields.quit and not running_games[pname].running then
            -- Pressed Esc in the game over screen
            minetest.after(0.1, minetest.show_formspec, pname, "prang:fs",
                player:get_inventory_formspec())
        end
        return
    elseif not running_games[pname].running then
        -- In the instructions/credits pages
        if fields.exit or fields.quit then
            player:set_inventory_formspec(TITLE_FS)
            if fields.quit then
                minetest.after(0.1, minetest.show_formspec, pname, "prang:fs",
                    TITLE_FS)
            elseif formname ~= "" then
                minetest.show_formspec(pname, "prang:fs", TITLE_FS)
            end
            running_games[pname].running = true
        end
        return
    end

    if fields.zoom_in then
        set_game_zoom(pname, min(zoom_levels[pname] + 0.05, 2))
    elseif fields.zoom_out then
        set_game_zoom(pname, max(zoom_levels[pname] - 0.05, 0.2))
    elseif fields.reset_zoom then
        set_game_zoom(pname, DEFAULT_ZOOM)
    elseif fields.toggle_sky then
        -- Disable clouds etc to save FPS
        if player:get_clouds().density == 0 then
            player:set_clouds({density = 0.4})
            player:set_sky({clouds = true})
            player:set_sun({visible = true, sunrise_visible = true})
            player:set_moon({visible = true})
            player:set_stars({visible = true})
            hud_fs.close_hud(pname, "prang:bg")
        else
            hide_sky(player, pname)
        end
    elseif fields.start then
        minetest.close_formspec(pname, "")
        running_games[pname]:shutdown()
        running_games[pname] = Game(player)
        player:set_inventory_formspec(IN_GAME_FS)
    elseif fields.instructions then
        show_instructions_credits(player, pname, formname,
            "prang_instructions_bg.png")
    elseif fields.credits then
        show_instructions_credits(player, pname, formname,
            "prang_credits_bg.jpg")
    elseif fields.exit then
        minetest.kick_player(pname, "Thank you for playing PRANG!")
    elseif fields.quit then
        minetest.after(0.1, minetest.show_formspec, pname, "prang:fs",
            TITLE_FS)
    end
end)
