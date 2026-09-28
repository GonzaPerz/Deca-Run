-- =================== CLASE ENEMIGO ===================
local Enemigo = {}
Enemigo.__index = Enemigo

function Enemigo:Nuevo(x, y, tipo, vel)
    local o = setmetatable({}, Enemigo)
    o.x = x; o.y = y; o.tipo = tipo; o.velocidad = vel
    o.vivo = true; o.moviendose = false
    
    if tipo == "slime" then
        o.img_quieto = Texturas.slime_quieto; o.img_mov = Texturas.slime_mov
    elseif tipo == "esqueleto" then
        o.img_quieto = Texturas.esqueleto_quieto; o.img_mov = Texturas.esqueleto_mov
    elseif tipo == "arana" then
        o.img_quieto = Texturas.arana_quieto; o.img_mov = Texturas.arana_mov
    end

    o.ancho = o.img_quieto:getWidth()
    o.alto = o.img_quieto:getHeight()
    
    -- Ajuste de Hitbox seguro para sprites pequeños
    o.hit_ox = 2; o.hit_oy = 2
    o.hit_w = math.max(4, o.ancho - 4)
    o.hit_h = math.max(4, o.alto - 4)

    o.quads_mov = crearAnimacion(o.img_mov, 2)
    o.anim_index = 1
    o.anim_vel = 6 
    
    return o
end

function Enemigo:Actualizar(dt, target_x, target_y)
    if not self.vivo then return end
    
    local movido = false
    if self.x < target_x - 5 then self.x = self.x + (self.velocidad * dt); movido = true
    elseif self.x > target_x + 5 then self.x = self.x - (self.velocidad * dt); movido = true end
    
    if self.y < target_y - 5 then self.y = self.y + (self.velocidad * dt); movido = true
    elseif self.y > target_y + 5 then self.y = self.y - (self.velocidad * dt); movido = true end

    self.moviendose = movido
    if self.moviendose then
        self.anim_index = self.anim_index + (self.anim_vel * dt)
        if self.anim_index >= 3 then self.anim_index = 1 end
    else
        self.anim_index = 1
    end
end

return Enemigo