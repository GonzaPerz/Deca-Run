-- =================== CLASE ENEMIGO ===================
local Enemigo = {}
Enemigo.__index = Enemigo

function Enemigo:Nuevo(x, y, tipo, vel)
    local o = setmetatable({}, Enemigo)
    o.x = x; o.y = y; o.tipo = tipo; o.vel = vel or 40
    o.vivo = true; o.moviendose = true; o.anim_index = 1
    o.atacando = false

    local key_q = tipo and (tipo .. "_quieto") 
    local key_m = tipo and (tipo .. "_mov")
    local key_a = tipo and (tipo .. "_atacar")

    o.img_mov = Texturas[key_m] or Texturas.esqueleto_mov
    o.img_quieto = Texturas[key_q] or o.img_mov
    o.img_atacar = Texturas[key_a] or o.img_mov
        
    o.frames_quieto = o.img_quieto and math.floor(o.img_quieto:getWidth() / o.img_quieto:getHeight()) or 1
    if o.frames_quieto < 1 then o.frames_quieto = 1 end

    o.frames_mov = o.img_mov and math.floor(o.img_mov:getWidth() / o.img_mov:getHeight()) or 1
    if o.frames_mov < 1 then o.frames_mov = 1 end

    o.frames_atacar = o.img_atacar and math.floor(o.img_atacar:getWidth() / o.img_atacar:getHeight()) or 1
    if o.frames_atacar < 1 then o.frames_atacar = 1 end

    o.ancho_quieto = o.img_quieto and (o.img_quieto:getWidth() / o.frames_quieto) or 32
    o.alto_quieto = o.img_quieto and o.img_quieto:getHeight() or 32
    o.ancho_mov = o.img_mov and (o.img_mov:getWidth() / o.frames_mov) or 32
    o.alto_mov = o.img_mov and o.img_mov:getHeight() or 32
    o.ancho_atacar = o.img_atacar and (o.img_atacar:getWidth() / o.frames_atacar) or o.ancho_quieto
    o.alto_atacar = o.img_atacar and o.img_atacar:getHeight() or o.alto_quieto
    
    o.quads_quieto = o:GenerarQuads(o.img_quieto, o.frames_quieto, o.ancho_quieto, o.alto_quieto)
    o.quads_mov = o:GenerarQuads(o.img_mov, o.frames_mov, o.ancho_mov, o.alto_mov)
    o.quads_atacar = o.img_atacar and o:GenerarQuads(o.img_atacar, o.frames_atacar, o.ancho_atacar, o.alto_atacar) or {}

    o.hit_w = o.ancho_quieto * 0.45
    o.hit_h = o.alto_quieto * 0.55
    o.hit_ox = (o.ancho_quieto - o.hit_w) / 2
    o.hit_oy = o.alto_quieto - o.hit_h
    
    return o
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
    
    self.anim_index = self.anim_index + 8 * dt
    local max_frames = self.moviendose and #self.quads_mov or #self.quads_quieto
    if self.atacando and #self.quads_atacar > 0 then max_frames = #self.quads_atacar end

    if self.anim_index >= (max_frames + 1) then self.anim_index = 1 end
end

return Enemigo