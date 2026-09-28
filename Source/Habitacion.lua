-- =================== CLASE HABITACION ===================
local Habitacion = {}
Habitacion.__index = Habitacion

function Habitacion:Nueva(ancho_tiles, alto_tiles, lado_prohibido)
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

    -- 1=Arriba, 2=Derecha, 3=Abajo, 4=Izquierda
    local lados_validos = {}
    for i = 1, 4 do
        if i ~= lado_prohibido then
            table.insert(lados_validos, i)
        end
    end
    
    
    o.lado_puerta = lados_validos[math.random(1, #lados_validos)]

    -- Se posiciona la puerta evitando las esquinas
    if o.lado_puerta == 1 then -- Arriba
        o.puerta_col = math.random(1, o.ancho - 2)
        o.puerta_row = 0
    elseif o.lado_puerta == 2 then -- Derecha
        o.puerta_col = o.ancho - 1
        o.puerta_row = math.random(1, o.alto - 2)
    elseif o.lado_puerta == 3 then -- Abajo
        o.puerta_col = math.random(1, o.ancho - 2)
        o.puerta_row = o.alto - 1
    elseif o.lado_puerta == 4 then -- Izquierda
        o.puerta_col = 0
        o.puerta_row = math.random(1, o.alto - 2)
    end

    return o
end

function Habitacion:GenerarEnemigos(EnemigoClass, player_x, player_y)
    local enemigos_generados = {}
    local tipos = {"slime", "esqueleto", "arana"}
    local cantidad = math.random(2, 5) 
    
    for i = 1, cantidad do
        local rand_x, rand_y
        local distancia = 0
        
        repeat
            rand_x = math.random(64, (self.ancho * self.tam_tile) - 64)
            rand_y = math.random(64, (self.alto * self.tam_tile) - 64)
            distancia = math.sqrt((rand_x - player_x)^2 + (rand_y - player_y)^2)
        until distancia > 120 

        local rand_tipo = tipos[math.random(1, 3)]
        local rand_vel = math.random(30, 70)
        table.insert(enemigos_generados, EnemigoClass:Nuevo(rand_x, rand_y, rand_tipo, rand_vel))
    end
    
    return enemigos_generados
end

function Habitacion:Dibujar(Texturas)
    for col = 0, self.ancho - 1 do
        for row = 0, self.alto - 1 do
            local x = (col * self.tam_tile) + 16
            local y = (row * self.tam_tile) + 16
            local is_puerta = (col == self.puerta_col and row == self.puerta_row)
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
            
            -- Dibujar la Puerta proceduralmente con su rotación correcta
            elseif is_puerta then
                local rot = 0
                if self.lado_puerta == 1 then rot = math.pi/2
                elseif self.lado_puerta == 2 then rot = math.pi
                elseif self.lado_puerta == 3 then rot = -math.pi/2
                elseif self.lado_puerta == 4 then rot = 0 end
                
                love.graphics.draw(Texturas.piso_pared, x, y, rot, 1, 1, 16, 16)
                love.graphics.draw(Texturas.puerta, x, y, rot, 1, 1, 16, 16)

            -- Paredes normales
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