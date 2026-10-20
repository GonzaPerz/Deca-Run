-- =================== CLASE ENEMIGO (PROVISORIA) ===================
local Enemigo = {}
Enemigo.__index = Enemigo

function Enemigo:Nuevo(x, y, tipo, vel)
    local o = setmetatable({}, Enemigo)
    o.x = x; o.y = y; o.tipo = tipo; o.vel = vel or 40
    o.vivo = true; o.moviendose = true; o.anim_index = 1
    
    o.img_quieto = Texturas[tipo .. "_quieto"] or Texturas.slime_quieto
    o.img_mov = Texturas[tipo .. "_mov"] or Texturas.slime_mov
    
    -- Autodetecta la cantidad de frames para no cortar a la mitad a los enemigos viejos
    o.frames_totales = math.floor(o.img_quieto:getWidth() / o.img_quieto:getHeight())
    if o.frames_totales < 1 then o.frames_totales = 1 end

    local frames_mov = math.floor(o.img_mov:getWidth() / o.img_mov:getHeight())
    if frames_mov < 1 then frames_mov = 1 end

    o.ancho_frame = o.img_quieto:getWidth() / o.frames_totales
    o.alto_frame = o.img_quieto:getHeight()
    local ancho_mov = o.img_mov:getWidth() / frames_mov
    
    o.quads_quieto = {}
    o.quads_mov = {}
    
    for i = 0, o.frames_totales - 1 do
        table.insert(o.quads_quieto, love.graphics.newQuad(i * o.ancho_frame, 0, o.ancho_frame, o.alto_frame, o.img_quieto:getDimensions()))
    end
    for i = 0, frames_mov - 1 do
        table.insert(o.quads_mov, love.graphics.newQuad(i * ancho_mov, 0, ancho_mov, o.img_mov:getHeight(), o.img_mov:getDimensions()))
    end

    o.hit_ox = 0; o.hit_oy = 0
    o.hit_w = o.ancho_frame; o.hit_h = o.alto_frame
    return o
end

function Enemigo:Actualizar(dt, player_x, player_y)
    if not self.vivo then return end
    
    local dx = player_x - self.x
    local dy = player_y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist > 1 then
        self.x = self.x + (dx/dist) * self.vel * dt
        self.y = self.y + (dy/dist) * self.vel * dt
        self.moviendose = true
    else
        self.moviendose = false
    end
    
    self.anim_index = self.anim_index + 6 * dt
    local max_frames = self.moviendose and #self.quads_mov or #self.quads_quieto
    if self.anim_index >= (max_frames + 1) then self.anim_index = 1 end
end

return Enemigo