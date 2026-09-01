-- =================== CLASE HABITACION ===================
local Habitacion = {}
Habitacion.__index = Habitacion

function Habitacion:Nueva(ancho_tiles, alto_tiles)
    local o = setmetatable({}, Habitacion)
    o.ancho = ancho_tiles
    o.alto = alto_tiles
    o.tam_tile = 32
    o.grilla = {}
    
    math.randomseed(os.time())
    for col = 0, o.ancho - 1 do
        o.grilla[col] = {}
        for row = 0, o.alto - 1 do
            o.grilla[col][row] = math.random(1, 3)
        end
    end
    return o
end

function Habitacion:Dibujar()
    for col = 0, self.ancho - 1 do
        for row = 0, self.alto - 1 do
            local x = (col * self.tam_tile) + 16
            local y = (row * self.tam_tile) + 16
            local id_piso = self.grilla[col][row]
            local tex_centro = Texturas["piso_medio" .. id_piso]

            if col == 0 and row == 0 then
                love.graphics.draw(Texturas.piso_esquina, x, y, 0, 1, 1, 16, 16)
                love.graphics.draw(Texturas.esquina, x, y, 0, 1, 1, 16, 16)
            elseif col == self.ancho - 1 and row == 0 then
                love.graphics.draw(Texturas.piso_esquina, x, y, math.pi/2, 1, 1, 16, 16)
                love.graphics.draw(Texturas.esquina, x, y, math.pi/2, 1, 1, 16, 16)
            elseif col == self.ancho - 1 and row == self.alto - 1 then
                love.graphics.draw(Texturas.piso_esquina, x, y, math.pi, 1, 1, 16, 16)
                love.graphics.draw(Texturas.esquina, x, y, math.pi, 1, 1, 16, 16)
            elseif col == 0 and row == self.alto - 1 then
                love.graphics.draw(Texturas.piso_esquina, x, y, -math.pi/2, 1, 1, 16, 16)
                love.graphics.draw(Texturas.esquina, x, y, -math.pi/2, 1, 1, 16, 16)
            elseif col == 0 then
                love.graphics.draw(Texturas.piso_pared, x, y, 0, 1, 1, 16, 16)
                love.graphics.draw(Texturas.pared, x, y, 0, 1, 1, 16, 16)
            elseif row == 0 then
                love.graphics.draw(Texturas.piso_pared, x, y, math.pi/2, 1, 1, 16, 16)
                love.graphics.draw(Texturas.pared, x, y, math.pi/2, 1, 1, 16, 16)
            elseif col == self.ancho - 1 then
                love.graphics.draw(Texturas.piso_pared, x, y, math.pi, 1, 1, 16, 16)
                love.graphics.draw(Texturas.pared, x, y, math.pi, 1, 1, 16, 16)
            elseif row == self.alto - 1 then
                love.graphics.draw(Texturas.piso_pared, x, y, -math.pi/2, 1, 1, 16, 16)
                love.graphics.draw(Texturas.pared, x, y, -math.pi/2, 1, 1, 16, 16)
            else
                love.graphics.draw(tex_centro, x, y, 0, 1, 1, 16, 16)
            end
        end
    end
end

return Habitacion