-- =================== DECLARACIONES Y POO ===================
local Texturas = {}
local ESCALA_MUNDO = 2

-- Clase Enemigo
Enemigo = {}
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
    
    o.hit_ox = 6; o.hit_oy = 6
    o.hit_w = o.ancho - 12; o.hit_h = o.alto - 12

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

-- Jugador
Jugador = {
    x = 200, y = 150, vel = 120, 
    moviendose = false, anim_index = 1, anim_vel = 8,
    mirando = "abajo", 
    atacando = false, ataque_timer = 0, ataque_duracion = 0.25
}

-- Estado del Juego
Juego = { gameover = false, victoria = false, enemigos = {} }
Mapa = { ancho = 12, alto = 9, tam_tile = 32, grilla = {} } 

-- Calculo de centrado de la habitacion
local offsetX = (800 / ESCALA_MUNDO - (Mapa.ancho * Mapa.tam_tile)) / 2
local offsetY = (600 / ESCALA_MUNDO - (Mapa.alto * Mapa.tam_tile)) / 2

-- Funciones Auxiliares
function hayColision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function crearAnimacion(imagen, cant_frames)
    local ancho = imagen:getWidth() / cant_frames
    local alto = imagen:getHeight()
    local quads = {}
    for i = 0, cant_frames - 1 do
        table.insert(quads, love.graphics.newQuad(i * ancho, 0, ancho, alto, imagen:getDimensions()))
    end
    return quads
end

-- =================== INICIALIZACION ===================
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setNewFont(36) 

    Texturas.esquina = love.graphics.newImage("Sprites/Esquina.png")
    Texturas.pared = love.graphics.newImage("Sprites/Pared.png")
    Texturas.piso_esquina = love.graphics.newImage("Sprites/piso_esquina.png")
    Texturas.piso_pared = love.graphics.newImage("Sprites/piso_pared.png")
    Texturas.piso_medio1 = love.graphics.newImage("Sprites/piso_medio1.png")
    Texturas.piso_medio2 = love.graphics.newImage("Sprites/piso_medio2.png")
    Texturas.piso_medio3 = love.graphics.newImage("Sprites/piso_medio3.png")
    
    math.randomseed(os.time())
    for col = 0, Mapa.ancho - 1 do
        Mapa.grilla[col] = {}
        for row = 0, Mapa.alto - 1 do
            Mapa.grilla[col][row] = math.random(1, 3)
        end
    end

    Texturas.jugador_quieto = love.graphics.newImage("Sprites/Sprite-0002.png")
    Texturas.jugador_mov = love.graphics.newImage("Sprites/Sprite-0002pt2.png")
    Texturas.espada = love.graphics.newImage("Sprites/Espada.png")
    
    Jugador.ancho = Texturas.jugador_quieto:getWidth()
    Jugador.alto = Texturas.jugador_quieto:getHeight()
    Jugador.hit_ox = 8; Jugador.hit_oy = 8
    Jugador.hit_w = Jugador.ancho - 16; Jugador.hit_h = Jugador.alto - 16
    Jugador.quads_mov = crearAnimacion(Texturas.jugador_mov, 2)

    Texturas.slime_quieto = love.graphics.newImage("Sprites/Slime_quieto.png")
    Texturas.slime_mov = love.graphics.newImage("Sprites/Slime_moviendose.png")
    Texturas.esqueleto_quieto = love.graphics.newImage("Sprites/Esqueleto_quieto.png")
    Texturas.esqueleto_mov = love.graphics.newImage("Sprites/Esqueleto_moviendose.png")
    Texturas.arana_quieto = love.graphics.newImage("Sprites/Araña.png")
    Texturas.arana_mov = love.graphics.newImage("Sprites/Araña_movienose.png")
    

    Sonido_ataque = love.audio.newSource("Sounds/ataque.mp3","static")
    Sonido_golpe = love.audio.newSource("Sounds/golpe.mp3","static")


    table.insert(Juego.enemigos, Enemigo:Nuevo(80, 80, "slime", 25))
    table.insert(Juego.enemigos, Enemigo:Nuevo(280, 80, "slime", 25))
    table.insert(Juego.enemigos, Enemigo:Nuevo(250, 150, "esqueleto", 35))
    table.insert(Juego.enemigos, Enemigo:Nuevo(250, 250, "esqueleto", 35))
    table.insert(Juego.enemigos, Enemigo:Nuevo(100, 200, "arana", 50))
    table.insert(Juego.enemigos, Enemigo:Nuevo(150, 200, "arana", 50))
end

-- =================== INTERACCION ===================
function love.keypressed(key)
    if key == "space" and not Jugador.atacando then
        Jugador.atacando = true
        Jugador.ataque_timer = Jugador.ataque_duracion
        
        Sonido_ataque:play()

        local hit_x, hit_y = Jugador.x, Jugador.y
        local hit_w, hit_h = 35, 35
        
        if Jugador.mirando == "arriba" then hit_y = Jugador.y - hit_h
        elseif Jugador.mirando == "abajo" then hit_y = Jugador.y + Jugador.alto
        elseif Jugador.mirando == "izquierda" then hit_x = Jugador.x - hit_w
        elseif Jugador.mirando == "derecha" then hit_x = Jugador.x + Jugador.ancho end
        
        for _, enemigo in ipairs(Juego.enemigos) do
            local ex = enemigo.x + enemigo.hit_ox
            local ey = enemigo.y + enemigo.hit_oy
            if enemigo.vivo and hayColision(hit_x, hit_y, hit_w, hit_h, ex, ey, enemigo.hit_w, enemigo.hit_h) then
                enemigo.vivo = false
                Sonido_golpe:play()
            end
        end
    end
end

-- =================== ACTUALIZACION ===================
function love.update(dt)
    if Juego.gameover or Juego.victoria then return end

    if Jugador.atacando then
        Jugador.ataque_timer = Jugador.ataque_timer - dt
        if Jugador.ataque_timer <= 0 then Jugador.atacando = false end
    end

    local dx, dy = 0, 0
    if not Jugador.atacando then
        if love.keyboard.isDown("left", "a") then dx = -1; Jugador.mirando = "izquierda" end
        if love.keyboard.isDown("right", "d") then dx = 1; Jugador.mirando = "derecha" end
        if love.keyboard.isDown("up", "w") then dy = -1; Jugador.mirando = "arriba" end
        if love.keyboard.isDown("down", "s") then dy = 1; Jugador.mirando = "abajo" end
        
        if dx ~= 0 or dy ~= 0 then
            Jugador.moviendose = true
            local norma = math.sqrt(dx * dx + dy * dy)
            Jugador.x = Jugador.x + (dx / norma * Jugador.vel * dt)
            Jugador.y = Jugador.y + (dy / norma * Jugador.vel * dt)
        else
            Jugador.moviendose = false
        end
    end

    if Jugador.moviendose then
        Jugador.anim_index = Jugador.anim_index + (Jugador.anim_vel * dt)
        if Jugador.anim_index >= 3 then Jugador.anim_index = 1 end
    else
        Jugador.anim_index = 1
    end

    local enemigosVivos = 0
    local jx = Jugador.x + Jugador.hit_ox
    local jy = Jugador.y + Jugador.hit_oy

    for _, enemigo in ipairs(Juego.enemigos) do
        if enemigo.vivo then
            enemigosVivos = enemigosVivos + 1
            enemigo:Actualizar(dt, Jugador.x, Jugador.y)
            
            local ex = enemigo.x + enemigo.hit_ox
            local ey = enemigo.y + enemigo.hit_oy
            
            if hayColision(jx, jy, Jugador.hit_w, Jugador.hit_h, ex, ey, enemigo.hit_w, enemigo.hit_h) then
                Juego.gameover = true
            end
        end
    end
    
    if enemigosVivos == 0 then Juego.victoria = true end
end

-- =================== RENDERIZADO ===================
function love.draw()
    love.graphics.push()
    love.graphics.scale(ESCALA_MUNDO, ESCALA_MUNDO)
    love.graphics.translate(offsetX, offsetY)

    for col = 0, Mapa.ancho - 1 do
        for row = 0, Mapa.alto - 1 do
            local x = (col * Mapa.tam_tile) + 16
            local y = (row * Mapa.tam_tile) + 16
            
            local id_piso = Mapa.grilla[col][row]
            local tex_centro = Texturas["piso_medio" .. id_piso]

            if col == 0 and row == 0 then
                love.graphics.draw(Texturas.piso_esquina, x, y, 0, 1, 1, 16, 16)
                love.graphics.draw(Texturas.esquina, x, y, 0, 1, 1, 16, 16)
            elseif col == Mapa.ancho - 1 and row == 0 then
                love.graphics.draw(Texturas.piso_esquina, x, y, math.pi/2, 1, 1, 16, 16)
                love.graphics.draw(Texturas.esquina, x, y, math.pi/2, 1, 1, 16, 16)
            elseif col == Mapa.ancho - 1 and row == Mapa.alto - 1 then
                love.graphics.draw(Texturas.piso_esquina, x, y, math.pi, 1, 1, 16, 16)
                love.graphics.draw(Texturas.esquina, x, y, math.pi, 1, 1, 16, 16)
            elseif col == 0 and row == Mapa.alto - 1 then
                love.graphics.draw(Texturas.piso_esquina, x, y, -math.pi/2, 1, 1, 16, 16)
                love.graphics.draw(Texturas.esquina, x, y, -math.pi/2, 1, 1, 16, 16)
            elseif col == 0 then
                love.graphics.draw(Texturas.piso_pared, x, y, 0, 1, 1, 16, 16)
                love.graphics.draw(Texturas.pared, x, y, 0, 1, 1, 16, 16)
            elseif row == 0 then
                love.graphics.draw(Texturas.piso_pared, x, y, math.pi/2, 1, 1, 16, 16)
                love.graphics.draw(Texturas.pared, x, y, math.pi/2, 1, 1, 16, 16)
            elseif col == Mapa.ancho - 1 then
                love.graphics.draw(Texturas.piso_pared, x, y, math.pi, 1, 1, 16, 16)
                love.graphics.draw(Texturas.pared, x, y, math.pi, 1, 1, 16, 16)
            elseif row == Mapa.alto - 1 then
                love.graphics.draw(Texturas.piso_pared, x, y, -math.pi/2, 1, 1, 16, 16)
                love.graphics.draw(Texturas.pared, x, y, -math.pi/2, 1, 1, 16, 16)
            else
                love.graphics.draw(tex_centro, x, y, 0, 1, 1, 16, 16)
            end
        end
    end
    
    if Jugador.moviendose then
        local frame = math.floor(Jugador.anim_index)
        love.graphics.draw(Texturas.jugador_mov, Jugador.quads_mov[frame], Jugador.x, Jugador.y)
    else
        love.graphics.draw(Texturas.jugador_quieto, Jugador.x, Jugador.y)
    end
    
    if Jugador.atacando then
        local progreso = 1 - (Jugador.ataque_timer / Jugador.ataque_duracion)
        local angulo_base = 0
        
        if Jugador.mirando == "derecha" then angulo_base = math.pi / 2
        elseif Jugador.mirando == "abajo" then angulo_base = math.pi
        elseif Jugador.mirando == "izquierda" then angulo_base = -math.pi / 2 end
        
        local rotacion_tajo = angulo_base - 0.8 + (1.6 * progreso)
        local ox = Texturas.espada:getWidth() / 2
        local oy = Texturas.espada:getHeight()
        local centro_jug_x = Jugador.x + (Jugador.ancho / 2)
        local centro_jug_y = Jugador.y + (Jugador.alto / 2)
        
        love.graphics.draw(Texturas.espada, centro_jug_x, centro_jug_y, rotacion_tajo, 0.7, 0.7, ox, oy)
    end
    
    for _, enemigo in ipairs(Juego.enemigos) do
        if enemigo.vivo then
            if enemigo.moviendose then
                local frame = math.floor(enemigo.anim_index)
                love.graphics.draw(enemigo.img_mov, enemigo.quads_mov[frame], enemigo.x, enemigo.y)
            else
                love.graphics.draw(enemigo.img_quieto, enemigo.x, enemigo.y)
            end
        end
    end

    love.graphics.pop() 

    if Juego.gameover then 
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("GAME OVER", 0, 250, 800, "center") 
    end
    if Juego.victoria then 
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf("CLEAR", 0, 250, 800, "center") 
    end
    love.graphics.setColor(1, 1, 1)
end