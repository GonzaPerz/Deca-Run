local Evento = require("Evento")
local Jefe = {}
Jefe.__index = Jefe

function Jefe:Nuevo(x, y)
    local o = setmetatable({}, Jefe)
    o.x = x; o.y = y; o.vel = 50
    o.hp = 100; o.max_hp = 100
    o.vivo = true
    o.estado = "perseguir"
    o.anim_index = 1
    o.mirando = "izquierda"

    o.img_idle = Texturas.boss_idle
    o.img_walk = Texturas.boss_walk
    o.img_attack = Texturas.boss_attack
    o.img_skill = Texturas.boss_skill

    o.frames_idle = math.floor(o.img_idle:getWidth() / o.img_idle:getHeight())
    o.frames_walk = math.floor(o.img_walk:getWidth() / o.img_walk:getHeight())
    o.frames_attack = math.floor(o.img_attack:getWidth() / o.img_attack:getHeight())
    o.frames_skill = math.floor(o.img_skill:getWidth() / o.img_skill:getHeight())

    o.ancho_idle = o.img_idle:getWidth() / o.frames_idle; o.alto_idle = o.img_idle:getHeight()
    o.ancho_walk = o.img_walk:getWidth() / o.frames_walk; o.alto_walk = o.img_walk:getHeight()
    o.ancho_attack = o.img_attack:getWidth() / o.frames_attack; o.alto_attack = o.img_attack:getHeight()
    o.ancho_skill = o.img_skill:getWidth() / o.frames_skill; o.alto_skill = o.img_skill:getHeight()

    o.hit_w = 40; o.hit_h = 50
    o.hit_ox = -20; o.hit_oy = -25

    o.quads_idle = o:GenerarQuads(o.img_idle, o.frames_idle, o.ancho_idle, o.alto_idle)
    o.quads_walk = o:GenerarQuads(o.img_walk, o.frames_walk, o.ancho_walk, o.alto_walk)
    o.quads_attack = o:GenerarQuads(o.img_attack, o.frames_attack, o.ancho_attack, o.alto_attack)
    o.quads_skill = o:GenerarQuads(o.img_skill, o.frames_skill, o.ancho_skill, o.alto_skill)

    o.timer_rutina = 0
    o.co_comportamiento = coroutine.create(function(self_ref)
        while true do
            self_ref.estado = "perseguir"
            coroutine.yield(3.5)

            self_ref.estado = "invocar"
            self_ref.anim_index = 1
            if self_ref.lista_enemigos and self_ref.clase_enemigo then
                table.insert(self_ref.lista_enemigos, self_ref.clase_enemigo:Nuevo(self_ref.x + 50, self_ref.y + 50, "summon", 60))
                table.insert(self_ref.lista_enemigos, self_ref.clase_enemigo:Nuevo(self_ref.x - 50, self_ref.y - 50, "summon", 60))
            end
            coroutine.yield(1.5)

            self_ref.estado = "perseguir"
            coroutine.yield(1.0)

            self_ref.estado = "atacar"
            self_ref.anim_index = 1
            coroutine.yield(1.2)
        end
    end)

    return o
end

function Jefe:GenerarQuads(img, total, w, h)
    local quads = {}
    for i = 0, total - 1 do
        table.insert(quads, love.graphics.newQuad(i * w, 0, w, h, img:getDimensions()))
    end
    return quads
end

function Jefe:Actualizar(dt, px, py, lista, clase)
    if not self.vivo then return end

    self.lista_enemigos = lista
    self.clase_enemigo = clase

    self.timer_rutina = self.timer_rutina - dt
    if self.timer_rutina <= 0 then
        if coroutine.status(self.co_comportamiento) ~= "dead" then
            local success, tiempo_espera = coroutine.resume(self.co_comportamiento, self)
            if success then
                self.timer_rutina = tiempo_espera or 0
            else
                print("Error interno en la rutina del jefe:", tiempo_espera)
                self.timer_rutina = 1 
            end
        end
    end

    local dx = px - self.x
    local dy = py - self.y
    local dist = math.sqrt(dx*dx + dy*dy)

    if dx < 0 then self.mirando = "izquierda" else self.mirando = "derecha" end

    if self.estado == "perseguir" and dist > 35 then
        self.x = self.x + (dx/dist) * self.vel * dt
        self.y = self.y + (dy/dist) * self.vel * dt
    end

    self.anim_index = self.anim_index + 8 * dt
    local limit = self.frames_idle
    if self.estado == "perseguir" then limit = self.frames_walk
    elseif self.estado == "atacar" then limit = self.frames_attack
    elseif self.estado == "invocar" then limit = self.frames_skill end

    if self.anim_index >= limit + 1 then self.anim_index = 1 end
end

function Jefe:ComprobarAtaqueJugador(jugador_x, jugador_y, jugador_w, jugador_h)
    if self.estado == "atacar" then
        local frame_actual = math.floor(self.anim_index)
        if frame_actual >= 3 and frame_actual <= 9 then
            local atk_w, atk_h = 60, 60
            local atk_x = (self.mirando == "izquierda") and (self.x - atk_w - 10) or (self.x + 10)
            local atk_y = self.y - 30

            return (atk_x < jugador_x + jugador_w and jugador_x < atk_x + atk_w) and 
                   (atk_y < jugador_y + jugador_h and jugador_y < atk_y + atk_h)
        end
    end
    return false
end

function Jefe:Dibujar()
    if not self.vivo then return end
    local img, quads, ox, oy
    if self.estado == "perseguir" then img = self.img_walk; quads = self.quads_walk; ox = self.ancho_walk/2; oy = self.alto_walk/2
    elseif self.estado == "atacar" then img = self.img_attack; quads = self.quads_attack; ox = self.ancho_attack/2; oy = self.alto_attack/2
    elseif self.estado == "invocar" then img = self.img_skill; quads = self.quads_skill; ox = self.ancho_skill/2; oy = self.alto_skill/2
    else img = self.img_idle; quads = self.quads_idle; ox = self.ancho_idle/2; oy = self.alto_idle/2 end

    local frame = math.floor(self.anim_index)
    if frame > #quads then frame = #quads end

    local sx = self.mirando == "izquierda" and -1 or 1
    love.graphics.draw(img, quads[frame], self.x, self.y, 0, sx, 1, ox, oy)
end

function Jefe:RecibirDano(dano)
    if not self.vivo then return end
    self.hp = self.hp - dano
    Evento.emit("boss_hp", self.hp, self.max_hp)
    if self.hp <= 0 then self.vivo = false end
end

return Jefe