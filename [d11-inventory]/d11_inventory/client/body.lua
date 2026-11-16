-- Arrastar ate o personagem de verdade para usar/equipar, sem o anel do whip_core (core/inv-body.js): o alvo e o corpo
-- inteiro na tela e, com o item em cima, o proprio personagem ganha um contorno na cor do tema. O renderer pergunta
-- (bodyBox) onde o corpo esta na tela enquanto arrasta e avisa (bodyHot) quando o item entra e sai dele.

local BONES = { 31086, 14201, 52301, 45509, 40269, 18905, 57005, 11816 }   -- cabeca, pes, bracos, maos, pelve
local ACCENT = { 0, 156, 228, 255 }                                        -- --accent do style.css (#009CE4)

local function yes(value) return value == true or value == 1 end
local outlined = 0   -- o ped com contorno agora (0: nenhum)

local function outline(on)
    local ped = on and PlayerPedId() or outlined
    if ped == 0 then return end
    if on then SetEntityDrawOutlineColor(ACCENT[1], ACCENT[2], ACCENT[3], ACCENT[4]) end
    SetEntityDrawOutline(ped, on)
    outlined = on and ped or 0
end

--- O retangulo do corpo na tela (0 a 1), ou nil (primeira pessoa, fora da tela).
local function box()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) and GetFollowPedCamViewMode() == 4 then return nil end
    local x0, y0, x1, y1, seen = 1.0, 1.0, 0.0, 0.0, 0
    for _, bone in ipairs(BONES) do
        local c = GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0)
        local ok, x, y = GetScreenCoordFromWorldCoord(c.x, c.y, c.z)
        if yes(ok) then
            seen = seen + 1
            x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
        end
    end
    if seen < 3 then return nil end
    -- folga: os ossos ficam por dentro da silhueta (cabeca, ombros, pes)
    local w, h = x1 - x0, y1 - y0
    local padX = math.max(w * 0.25, 0.012)
    return { x0 = x0 - padX, y0 = y0 - h * 0.08, x1 = x1 + padX, y1 = y1 + h * 0.03 }
end

-- off: o gesto esta desligado agora (config.lua ou um bloqueio): sem alvo no corpo nem na ficha
RegisterNUICallback('bodyBox', function(_, cb)
    if not D11Gestures.allowed('body') then return cb({ hidden = true, off = true }) end
    cb(box() or { hidden = true })
end)

RegisterNUICallback('bodyHot', function(data, cb)
    outline(type(data) == 'table' and data.on == true)
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and outlined ~= 0 then SetEntityDrawOutline(outlined, false) end
end)
