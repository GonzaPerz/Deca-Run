-- =================== CLASE JUGADOR ===================
local Evento = require("Evento")
local Jugador = {}
Jugador.__index = Jugador

function Jugador:Nuevo(x, y)
    local o = setmetatable({}, Jugador)
    o.x = x; o.y = y; o.vel = 150
    o.hp = 3 
    o.invulnerable = 0
    o.moviendose = false; o.anim_index = 1; o.anim_vel = 10
    o.mirando = "derecha" 
    o.atacando = false; o.ataque_timer = 0; o.ataque_duracion = 0.4

    o.img_idle = Texturas.jugador_idle
    o.img_walk = Texturas.jugador_walk
    o.img_attack = Texturas.jugador_attack

    o.frames_idle = 4; o.frames_walk = 6; o.frames_attack = 10

    o.ancho_idle = o.img_idle:getWidth() / o.frames_idle
    o.ancho_walk = o.img_walk:getWidth() / o.frames_walk
    o.ancho_attack = o.img_attack:getWidth() / o.frames_attack

    o.hit_ox = 18; o.hit_oy = 22; o.hit_w = 14; o.hit_h = 15    
    
    o.quads_idle = {}
    o.quads_walk = {}
    o.quads_attack = {}
    
    for i = 0, o.frames_idle - 1 do
        table.insert(o.quads_idle, love.graphics.newQuad(i * o.ancho_idle, 0, o.ancho_idle, o.img_idle:getHeight(), o.img_idle:getDimensions()))
    end
    for i = 0, o.frames_walk - 1 do
        table.insert(o.quads_walk, love.graphics.newQuad(i * o.ancho_walk, 0, o.ancho_walk, o.img_walk:getHeight(), o.img_walk:getDimensions()))
    end
    for i = 0, o.frames_attack - 1 do
        table.insert(o.quads_attack, love.graphics.newQuad(i * o.ancho_attack, 0, o.ancho_attack, o.img_attack:getHeight(), o.img_attack:getDimensions()))
    end
    
    return o
end

function Jugador:RecibirDano()
    if self.invulnerable <= 0 then
        self.hp = self.hp - 1
        self.invulnerable = 1.5
        return true
    end
    return false
end

function Jugador:Actualizar(dt)
    if self.invulnerable > 0 then self.invulnerable = self.invulnerable - dt end

    if self.atacando then
        self.ataque_timer = self.ataque_timer - dt
        self.anim_index = self.anim_index + (self.frames_attack / self.ataque_duracion) * dt
        if self.ataque_timer <= 0 then self.atacando = false end
    end

    local dx, dy = 0, 0
    if not self.atacando then
        if love.keyboard.isDown("left", "a") then dx = -1; self.mirando = "izquierda" end
        if love.keyboard.isDown("right", "d") then dx = 1; self.mirando = "derecha" end
        if love.keyboard.isDown("up", "w") then dy = -1 end
        if love.keyboard.isDown("down", "s") then dy = 1 end
        
        if dx ~= 0 or dy ~= 0 then
            self.moviendose = true
            local norma = math.sqrt(dx * dx + dy * dy)
            self.x = self.x + (dx / norma * self.vel * dt)
            self.y = self.y + (dy / norma * self.vel * dt)
        else
            self.moviendose = false
        end
    end

    if not self.atacando then
        self.anim_index = self.anim_index + (self.anim_vel * dt)
        local limit = self.moviendose and self.frames_walk or self.frames_idle
        if self.anim_index >= limit + 1 then self.anim_index = 1 end
    end
end

function Jugador:Dibujar()
    local img_actual, quads_actual, frame_limit, ancho_actual
    
    if self.atacando then
        img_actual = self.img_attack; quads_actual = self.quads_attack
        frame_limit = self.frames_attack; ancho_actual = self.ancho_attack
    elseif self.moviendose then
        img_actual = self.img_walk; quads_actual = self.quads_walk
        frame_limit = self.frames_walk; ancho_actual = self.ancho_walk
    else
        img_actual = self.img_idle; quads_actual = self.quads_idle
        frame_limit = self.frames_idle; ancho_actual = self.ancho_idle
    end

    local frame = math.floor(self.anim_index)
    if frame > frame_limit then frame = frame_limit end 
    if frame < 1 then frame = 1 end

    local scaleX, offsetX = 1, 0
    if self.mirando == "izquierda" then
        scaleX = -1; offsetX = ancho_actual
    end

    if self.invulnerable > 0 and math.floor(self.invulnerable * 10) % 2 == 0 then
        love.graphics.setColor(1, 0, 0, 0.6)
    end

    love.graphics.draw(img_actual, quads_actual[frame], self.x, self.y, 0, scaleX, 1, offsetX, 0)
    love.graphics.setColor(1, 1, 1)
end

function Jugador:Atacar(enemigos, jefe)
    if not self.atacando then
        self.atacando = true
        self.ataque_timer = self.ataque_duracion
        self.anim_index = 1 
        
        -- Emitimos el sonido del golpe
        Evento.emit("reproducir_sfx", "golpe")
        
        local hit_x, hit_y = self.x, self.y
        local hit_w, hit_h = 40, 40
        
        if self.mirando == "arriba" then hit_y = self.y - hit_h
        elseif self.mirando == "abajo" then hit_y = self.y + self.img_idle:getHeight()
        elseif self.mirando == "izquierda" then hit_x = self.x - hit_w
        elseif self.mirando == "derecha" then hit_x = self.x + self.ancho_idle end
        
        for _, enemigo in ipairs(enemigos) do
            local ex = enemigo.x + enemigo.hit_ox
            local ey = enemigo.y + enemigo.hit_oy
            if enemigo.vivo and hayColision(hit_x, hit_y, hit_w, hit_h, ex, ey, enemigo.hit_w, enemigo.hit_h) then
                enemigo.vivo = false
                Juego.puntaje = Juego.puntaje + 10
                Evento.emit("puntaje_actualizado")
            end
        end

        if jefe and jefe.vivo then
            local jx = jefe.x + jefe.hit_ox
            local jy = jefe.y + jefe.hit_oy
            if hayColision(hit_x, hit_y, hit_w, hit_h, jx, jy, jefe.hit_w, jefe.hit_h) then
                jefe:RecibirDano(10)
                Juego.puntaje = Juego.puntaje + 50
                Evento.emit("puntaje_actualizado")
            end
        end
    end
end

return Jugador