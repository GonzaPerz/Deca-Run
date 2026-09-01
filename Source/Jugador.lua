-- =================== CLASE JUGADOR ===================
local Jugador = {}
Jugador.__index = Jugador

function Jugador:Nuevo(x, y)
    local o = setmetatable({}, Jugador)
    o.x = x; o.y = y; o.vel = 120
    o.moviendose = false; o.anim_index = 1; o.anim_vel = 8
    o.mirando = "abajo"
    o.atacando = false; o.ataque_timer = 0; o.ataque_duracion = 0.25

    o.ancho = Texturas.jugador_quieto:getWidth()
    o.alto = Texturas.jugador_quieto:getHeight()
    o.hit_ox = 8; o.hit_oy = 8
    o.hit_w = o.ancho - 16; o.hit_h = o.alto - 16
    o.quads_mov = crearAnimacion(Texturas.jugador_mov, 2)
    
    return o
end

function Jugador:Atacar(enemigos)
    if not self.atacando then
        self.atacando = true
        self.ataque_timer = self.ataque_duracion
        
        Sonidos.ataque:stop()
        Sonidos.ataque:play()
        
        local hit_x, hit_y = self.x, self.y
        local hit_w, hit_h = 35, 35
        
        if self.mirando == "arriba" then hit_y = self.y - hit_h
        elseif self.mirando == "abajo" then hit_y = self.y + self.alto
        elseif self.mirando == "izquierda" then hit_x = self.x - hit_w
        elseif self.mirando == "derecha" then hit_x = self.x + self.ancho end
        
        for _, enemigo in ipairs(enemigos) do
            local ex = enemigo.x + enemigo.hit_ox
            local ey = enemigo.y + enemigo.hit_oy
            if enemigo.vivo and hayColision(hit_x, hit_y, hit_w, hit_h, ex, ey, enemigo.hit_w, enemigo.hit_h) then
                enemigo.vivo = false
                Sonidos.golpe:stop()
                Sonidos.golpe:play()
            end
        end
    end
end

function Jugador:Actualizar(dt)
    if self.atacando then
        self.ataque_timer = self.ataque_timer - dt
        if self.ataque_timer <= 0 then self.atacando = false end
    end

    local dx, dy = 0, 0
    if not self.atacando then
        if love.keyboard.isDown("left", "a") then dx = -1; self.mirando = "izquierda" end
        if love.keyboard.isDown("right", "d") then dx = 1; self.mirando = "derecha" end
        if love.keyboard.isDown("up", "w") then dy = -1; self.mirando = "arriba" end
        if love.keyboard.isDown("down", "s") then dy = 1; self.mirando = "abajo" end
        
        if dx ~= 0 or dy ~= 0 then
            self.moviendose = true
            local norma = math.sqrt(dx * dx + dy * dy)
            self.x = self.x + (dx / norma * self.vel * dt)
            self.y = self.y + (dy / norma * self.vel * dt)
        else
            self.moviendose = false
        end
    end

    if self.moviendose then
        self.anim_index = self.anim_index + (self.anim_vel * dt)
        if self.anim_index >= 3 then self.anim_index = 1 end
    else
        self.anim_index = 1
    end
end

function Jugador:Dibujar()
    if self.moviendose then
        local frame = math.floor(self.anim_index)
        love.graphics.draw(Texturas.jugador_mov, self.quads_mov[frame], self.x, self.y)
    else
        love.graphics.draw(Texturas.jugador_quieto, self.x, self.y)
    end
    
    if self.atacando then
        local progreso = 1 - (self.ataque_timer / self.ataque_duracion)
        local angulo_base = 0
        
        if self.mirando == "derecha" then angulo_base = math.pi / 2
        elseif self.mirando == "abajo" then angulo_base = math.pi
        elseif self.mirando == "izquierda" then angulo_base = -math.pi / 2 end
        
        local rotacion_tajo = angulo_base - 0.8 + (1.6 * progreso)
        local ox = Texturas.espada:getWidth() / 2
        local oy = Texturas.espada:getHeight()
        local centro_x = self.x + (self.ancho / 2)
        local centro_y = self.y + (self.alto / 2)
        
        love.graphics.draw(Texturas.espada, centro_x, centro_y, rotacion_tajo, 0.7, 0.7, ox, oy)
    end
end

return Jugador