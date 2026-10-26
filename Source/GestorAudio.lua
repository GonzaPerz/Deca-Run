local GestorAudio = {}
GestorAudio.__index = GestorAudio
local instancia_unica = nil

function GestorAudio.ObtenerInstancia()
    if not instancia_unica then
        instancia_unica = setmetatable({
            sfx = {},
            musica = nil,
            sfx_on = true,
            volumen = 1.0
        }, GestorAudio)
    end
    return instancia_unica
end

function GestorAudio:CargarAudios()
    local succ_golpe, src_golpe = pcall(love.audio.newSource, "Sounds/golpe.mp3", "static")
    if succ_golpe then self.sfx["golpe"] = src_golpe end
    
    local succ_ataque, src_ataque = pcall(love.audio.newSource, "Sounds/ataque.mp3", "static")
    if succ_ataque then self.sfx["ataque"] = src_ataque end
    
    local succ_dano, src_dano = pcall(love.audio.newSource, "Sounds/Player_hit.mp3", "static")
    if succ_dano then self.sfx["player_hit"] = src_dano end
    
    local succ_bgm, src_bgm = pcall(love.audio.newSource, "Sounds/musica.mp3", "stream")
    if succ_bgm then 
        self.musica = src_bgm 
        self.musica:setLooping(true)
    end
end

function GestorAudio:ReproducirSFX(nombre)
    if self.sfx_on and self.sfx[nombre] then
        local clon = self.sfx[nombre]:clone()
        clon:setVolume(self.volumen)
        clon:play()
    end
end

function GestorAudio:ActualizarVolumen(vol, musica_on, sfx_on)
    self.volumen = vol
    self.sfx_on = sfx_on
    if self.musica then
        self.musica:setVolume(vol)
        if musica_on and not self.musica:isPlaying() then
            self.musica:play()
        elseif not musica_on then
            self.musica:pause()
        end
    end
end

return GestorAudio