-- =================== CLASE HABITACION ===================
local Habitacion = {}
Habitacion.__index = Habitacion

function Habitacion:Nueva(min_tiles, max_tiles, lado_prohibido)
    local o = setmetatable({}, Habitacion)
    math.randomseed(os.time())
    o.ancho = math.random(min_tiles, max_tiles)
    o.alto = math.random(min_tiles, max_tiles)
    o.tam_tile = 32
    o.grilla = {}
    
    for col = 0, o.ancho - 1 do
        o.grilla[col] = {}
        for row = 0, o.alto - 1 do
            o.grilla[col][row] = math.random(1, 3)
        end
    end

    local lados_validos = {}
    for i = 1, 4 do
        if i ~= lado_prohibido then table.insert(lados_validos, i) end
    end
    
    o.lado_puerta = lados_validos[math.random(1, #lados_validos)]

    if o.lado_puerta == 1 then
        o.puerta_col = math.random(1, o.ancho - 2); o.puerta_row = 0
    elseif o.lado_puerta == 2 then
        o.puerta_col = o.ancho - 1; o.puerta_row = math.random(1, o.alto - 2)
    elseif o.lado_puerta == 3 then
        o.puerta_col = math.random(1, o.ancho - 2); o.puerta_row = o.alto - 1
    elseif o.lado_puerta == 4 then
        o.puerta_col = 0; o.puerta_row = math.random(1, o.alto - 2)
    end

    return o
end

function Habitacion:GenerarEnemigos(EnemigoClass, player_x, player_y)
    local enemigos_generados = {}
    local area_tiles = self.ancho * self.alto
    local cantidad = math.max(2, math.floor(area_tiles / 40)) 
    local tipos_posibles = {"esqueleto", "flyingeye", "goblin", "mushroom"} -- ACTUALIZADO CON TUS 4 ENEMIGOS
    
    for i = 1, cantidad do
        local rand_x, rand_y
        local distancia = 0
        
        repeat
            rand_x = math.random(64, (self.ancho * self.tam_tile) - 64)
            rand_y = math.random(64, (self.alto * self.tam_tile) - 64)
            distancia = math.sqrt((rand_x - player_x)^2 + (rand_y - player_y)^2)
        until distancia > 150 
        
        local rand_tipo = tipos_posibles[math.random(1, #tipos_posibles)]
        table.insert(enemigos_generados, EnemigoClass:Nuevo(rand_x, rand_y, rand_tipo, math.random(30, 70)))
    end
    return enemigos_generados
end

function Habitacion:Dibujar(Texturas)
    for col = 0, self.ancho - 1 do
        for row = 0, self.alto - 1 do
            local x = col * self.tam_tile
            local y = row * self.tam_tile
            local is_puerta = (col == self.puerta_col and row == self.puerta_row)

            love.graphics.setColor(1, 1, 1)

            local tex_centro = Texturas["piso_medio" .. self.grilla[col][row]]
            local sx_piso = self.tam_tile / tex_centro:getWidth()
            local sy_piso = self.tam_tile / tex_centro:getHeight()
            love.graphics.draw(tex_centro, x, y, 0, sx_piso, sy_piso)

            if is_puerta or (col == 0 or row == 0 or col == self.ancho - 1 or row == self.alto - 1) then
                local tex
                local rot = 0
                
                if is_puerta then
                    tex = Texturas.puerta
                    if row == 0 then rot = math.pi/2
                    elseif col == self.ancho - 1 then rot = math.pi
                    elseif row == self.alto - 1 then rot = -math.pi/2
                    elseif col == 0 then rot = 0 end
                elseif col == 0 and row == 0 then
                    tex = Texturas.esquina; rot = 0
                elseif col == self.ancho - 1 and row == 0 then
                    tex = Texturas.esquina; rot = math.pi/2
                elseif col == self.ancho - 1 and row == self.alto - 1 then
                    tex = Texturas.esquina; rot = math.pi
                elseif col == 0 and row == self.alto - 1 then
                    tex = Texturas.esquina; rot = -math.pi/2
                elseif row == 0 then
                    tex = Texturas.pared; rot = math.pi/2     
                elseif col == self.ancho - 1 then
                    tex = Texturas.pared; rot = math.pi       
                elseif row == self.alto - 1 then
                    tex = Texturas.pared; rot = -math.pi/2    
                elseif col == 0 then
                    tex = Texturas.pared; rot = 0             
                end

                local sx = self.tam_tile / tex:getWidth()
                local sy = self.tam_tile / tex:getHeight()
                local ox = tex:getWidth() / 2
                local oy = tex:getHeight() / 2

                love.graphics.draw(tex, x + self.tam_tile/2, y + self.tam_tile/2, rot, sx, sy, ox, oy)
            end
        end
    end
end

return Habitacion