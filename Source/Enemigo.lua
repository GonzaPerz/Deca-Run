-- =================== CLASE ENEMIGO ===================
local Enemigo = {}
Enemigo.__index = Enemigo

function Enemigo:Nuevo(x, y, tipo, vel)
    local o = setmetatable({}, Enemigo)
    o:Reconfigurar(x, y, tipo, vel)
    return o
end

function Enemigo:Reconfigurar(x, y, tipo, vel)
    self.x = x; self.y = y; self.tipo = tipo; self.vel = vel or 40
    self.vivo = true; self.moviendose = true; self.anim_index = 1
    self.atacando = false

    local key_q = tipo and (tipo .. "_quieto") 
    local key_m = tipo and (tipo .. "_mov")
    local key_a = tipo and (tipo .. "_atacar")

    self.img_mov = Texturas[key_m] or Texturas.esqueleto_mov
    self.img_quieto = Texturas[key_q] or self.img_mov
    self.img_atacar = Texturas[key_a] or self.img_mov
        
    self.frames_quieto = self.img_quieto and math.floor(self.img_quieto:getWidth() / self.img_quieto:getHeight()) or 1
    if self.frames_quieto < 1 then self.frames_quieto = 1 end

    self.frames_mov = self.img_mov and math.floor(self.img_mov:getWidth() / self.img_mov:getHeight()) or 1
    if self.frames_mov < 1 then self.frames_mov = 1 end

    self.frames_atacar = self.img_atacar and math.floor(self.img_atacar:getWidth() / self.img_atacar:getHeight()) or 1
    if self.frames_atacar < 1 then self.frames_atacar = 1 end

    self.ancho_quieto = self.img_quieto and (self.img_quieto:getWidth() / self.frames_quieto) or 32
    self.alto_quieto = self.img_quieto and self.img_quieto:getHeight() or 32
    self.ancho_mov = self.img_mov and (self.img_mov:getWidth() / self.frames_mov) or 32
    self.alto_mov = self.img_mov and self.img_mov:getHeight() or 32
    self.ancho_atacar = self.img_atacar and (self.img_atacar:getWidth() / self.frames_atacar) or self.ancho_quieto
    self.alto_atacar = self.img_atacar and self.img_atacar:getHeight() or self.alto_quieto
    
    self.quads_quieto = self:GenerarQuads(self.img_quieto, self.frames_quieto, self.ancho_quieto, self.alto_quieto)
    self.quads_mov = self:GenerarQuads(self.img_mov, self.frames_mov, self.ancho_mov, self.alto_mov)
    self.quads_atacar = self.img_atacar and self:GenerarQuads(self.img_atacar, self.frames_atacar, self.ancho_atacar, self.alto_atacar) or {}

    self.hit_w = self.ancho_quieto * 0.45
    self.hit_h = self.alto_quieto * 0.55
    self.hit_ox = (self.ancho_quieto - self.hit_w) / 2
    self.hit_oy = self.alto_quieto - self.hit_h
end

function Enemigo:GenerarQuads(img, total, w, h)
    local quads = {}
    if not img then return quads end
    for i = 0, total - 1 do
        table.insert(quads, love.graphics.newQuad(i * w, 0, w, h, img:getDimensions()))
    end
    return quads
end

function Enemigo:Actualizar(dt, player_x, player_y)
    if not self.vivo then return end
    
    local dx = player_x - self.x
    local dy = player_y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist > 35 then
        self.x = self.x + (dx/dist) * self.vel * dt
        self.y = self.y + (dy/dist) * self.vel * dt
        self.moviendose = true
        self.atacando = false
    else
        self.moviendose = false
        self.atacando = true
    end
    
    self.anim_index = self.anim_index + 6 * dt
    local max_frames = self.moviendose and #self.quads_mov or #self.quads_quieto
    if self.atacando and #self.quads_atacar > 0 then max_frames = #self.quads_atacar end

    if self.anim_index >= (max_frames + 1) then self.anim_index = 1 end
end

return Enemigo