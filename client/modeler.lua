QBCore = exports['qb-core']:GetCoreObject()

local Freecam = exports['fivem-freecam']


local function CamThread()
    CreateThread(function()
        local IsDisabledControlJustPressed = IsDisabledControlJustPressed
        local DisableControlAction = DisableControlAction
        while IsFreecamMode do
            if IsDisabledControlJustPressed(0, 26) then -- C
                IsFreecamMode = false
                FreecamMode(false)
                break
            end
            DisableControlAction(0, 199, true) -- P
            DisableControlAction(0, 200, true) -- ESC
            Wait(0)
        end
    end)
end

local function isInside(coords)
    local extent = shellMinMax

    local isX = coords.x >= extent.min.x and coords.x <= extent.max.x
    local isY = coords.y >= extent.min.y and coords.y <= extent.max.y
    local isZ = coords.z >= extent.min.z and coords.z <= extent.max.z
    if isX and isY and isZ then
        return true
    end

    return false

end

local function getMinMax(shellPos, shellMin, shellMax)
    local min = vector3(shellPos.x + shellMin.x, shellPos.y + shellMin.y, shellPos.z + shellMin.z)
    local max = vector3(shellPos.x + shellMax.x, shellPos.y + shellMax.y, shellPos.z + shellMax.z)
    
    return {min = min, max = max}
end


AddEventHandler('freecam:onTick', function()
    if not IsFreecamMode then return end

    local update = true
    local lookAt =  Freecam:GetTarget(5.0)
    local camPos = Freecam:GetPosition()

    -- see if camPos is the same as the last one
    if CurrentCameraPosition and CurrentCameraLookAt then
        local posX = CurrentCameraPosition.x == camPos.x
        local posY = CurrentCameraPosition.y == camPos.y
        local posZ = CurrentCameraPosition.z == camPos.z

        local lookAtX = CurrentCameraLookAt.x == lookAt.x
        local lookAtY = CurrentCameraLookAt.y == lookAt.y
        local lookAtZ = CurrentCameraLookAt.z == lookAt.z

        if posX and posY and posZ and lookAtX and lookAtY and lookAtZ then
            return
        end
    end

    if not isInside(camPos) then
        Freecam:SetPosition(CurrentCameraPosition.x, CurrentCameraPosition.y, CurrentCameraPosition.z)
        update = false
    end

    if update then
        CurrentCameraLookAt =  lookAt
        CurrentCameraPosition = camPos
    end

    SendNUIMessage({
        action = "updateCamera",
        data = {
            cameraPosition = CurrentCameraPosition,
            cameraLookAt = CurrentCameraLookAt,
        }
    })
end)

RegisterNetEvent("ps-housing:client:openFurniture123", function(model, currentStore, shopObj, furnitures)
    OpenMenu(model, shopObj, furnitures, currentStore)
end)

IsMenuActive = false
IsFreecamMode = false

storeId = nil
furnitures = {}

shellPos = nil
shellMinMax = nil

CurrentObject = nil
CurrentCameraPosition = nil
CurrentCameraLookAt = nil
CurrentObjectAlpha = 200

Cart = {}

-- Hover stuff
IsHovering = false
HoverObject = nil
HoverDistance = 5.0

OpenMenu = function(shopType, shopObj, furnitures, id)

    shellPos = GetEntityCoords(shopObj)

    local min, max = GetModelDimensions(shopType)
    furnitures = furnitures
    shellMinMax = getMinMax(shellPos, min, max)
    storeId = id
    IsMenuActive = true

    SendNUIMessage({
        action = "setVisible",
        data = true
    })

    SendNUIMessage({
        action = "setFurnituresData",
        data = Config.Furnitures
    })

    -- Owned furniture is set by the Property class
    SetNuiFocus(true, true)
    FreecamActive(true)
    FreecamMode(false)
end

CloseMenu = function(self)
    IsMenuActive = false
    ClearCart()

    SendNUIMessage({
        action = "setOwnedItems",
        data = {},
    })

    SendNUIMessage({
        action = "setVisible",
        data = false
    })

    SetNuiFocus(false, false)

    HoverOut()
    StopPlacement()
    FreecamActive(false)

    Wait(500)

    CurrentCameraPosition = nil
    CurrentCameraLookAt = nil
    CurrentObject = nil
end

FreecamActive = function(bool)
    if bool then
        Freecam:SetActive(true)
        Freecam:SetKeyboardSetting('BASE_MOVE_MULTIPLIER', 0.1)
        Freecam:SetKeyboardSetting('FAST_MOVE_MULTIPLIER', 2)
        Freecam:SetKeyboardSetting('SLOW_MOVE_MULTIPLIER', 2)
        Freecam:SetFov(45.0)
        IsFreecamMode = true
    else
        Freecam:SetActive(false)
        --reset to default
        Freecam:SetKeyboardSetting('BASE_MOVE_MULTIPLIER', 5)
        Freecam:SetKeyboardSetting('FAST_MOVE_MULTIPLIER', 10)
        Freecam:SetKeyboardSetting('SLOW_MOVE_MULTIPLIER', 10)
        IsFreecamMode = false
    end
end

FreecamMode = function(bool)
    if bool then --not in UI
        IsFreecamMode = true
        CamThread()
        Freecam:SetFrozen(false)
        SetNuiFocus(false, false)
    else -- in UI
        IsFreecamMode = false
        Freecam:SetFrozen(true)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "freecamMode",
            data = false
        })
    end
end

StartPlacement = function(data)
    HoverOut() -- stops the hover effect on the previous object because sometimes mouseleave doesnt work
    local object = data.object
    local curObject
    local objectRot
    local objectPos

    CurrentCameraLookAt =  Freecam:GetTarget(5.0)
    CurrentCameraPosition = Freecam:GetPosition()

    if data.entity then --if the object is already spawned
        curObject = data.entity
        objectPos = GetEntityCoords(curObject)
        objectRot = GetEntityRotation(curObject)
    else 
        StopPlacement()
        lib.requestModel(object)

        curObject = CreateObject(GetHashKey(object), 0.0, 0.0, 0.0, false, true, false)
        SetEntityCoords(curObject, CurrentCameraLookAt.x, CurrentCameraLookAt.y, CurrentCameraLookAt.z)

        objectRot = GetEntityRotation(curObject)
        objectPos = CurrentCameraLookAt
    end

    FreezeEntityPosition(curObject, true)
    SetEntityCollision(curObject, false, false)
    SetEntityAlpha(curObject, CurrentObjectAlpha, false)
    SetEntityDrawOutline(curObject, true)
    SetEntityDrawOutlineColor(255, 255, 255, 255)
    SetEntityDrawOutlineShader(0)

    SendNUIMessage({
        action = "setObjectAlpha",
        data = CurrentObjectAlpha
    })

    SendNUIMessage({ 
        action = "setupModel",
        data = {
            objectPosition = objectPos,
            objectRotation = objectRot,
            cameraPosition = CurrentCameraPosition,
            cameraLookAt = CurrentCameraLookAt,
            entity = data.entity,
        }
    })

    SetNuiFocus(true, true)
    CurrentObject = curObject
end

MoveObject = function (data)
    local coords = vec3(data.x + 0.0, data.y + 0.0, data.z + 0.0)
    if not isInside(coords) then
        return
    end

    SetEntityCoords(CurrentObject, coords)
    -- get the current offset of this object in relation to the 
end

RotateObject = function (data)
    SetEntityRotation(CurrentObject, data.x + 0.0, data.y + 0.0, data.z + 0.0)
end

StopPlacement = function (self)
    if CurrentObject == nil then return end

    local canDelete = true
    for k, v in pairs(Cart) do
        if k == CurrentObject then
            canDelete = false
            break
        end
    end
    -- furnitureObjs
    -- see if its an owned object
    local ownedfurnitures = furnitures
    for i = 1, #ownedfurnitures do
        if ownedfurnitures[i].entity == CurrentObject then
            UpdateFurniture(ownedfurnitures[i])
            canDelete = false
            break
        end
    end

    if canDelete then
        DeleteEntity(CurrentObject)
    end

    SetEntityDrawOutline(CurrentObject, false)
    SetEntityAlpha(CurrentObject, 255, false)
    CurrentObject = nil
end

UpdateFurnitures = function(furnitureObjs)

    if not IsMenuActive then
        return
    end

    SendNUIMessage({
        action = "setOwnedItems",
        data = furnitureObjs,
    })
end
exports("UpdateFurnitures", UpdateFurnitures)

-- can be better
-- everytime "Stop Placement" is pressed on an owned object, it will update the furniture 
-- maybe should do it all at once when the user leaves the menu????
UpdateFurniture = function (item)
    local newPos = GetEntityCoords(item.entity)
    local newRot = GetEntityRotation(item.entity)

    local offsetPos = {
            x = math.floor((newPos.x - shellPos.x) * 10000) / 10000,
            y = math.floor((newPos.y - shellPos.y) * 10000) / 10000,
            z = math.floor((newPos.z - shellPos.z) * 10000) / 10000,
    }

    local newFurniture = {
        id = item.id,
        label = item.label,
        object = item.object,
        position = offsetPos,
        rotation = newRot,
        type = item.type,
    }

    TriggerServerEvent("ps-housing-edited:server:updateFurniture", storeId, furnitures,newFurniture)
end

SetObjectAlpha = function (data)
    CurrentObjectAlpha = data.alpha
    SetEntityAlpha(CurrentObject, CurrentObjectAlpha, false)
end

PlaceOnGround = function (self)
    local x, y, z = table.unpack(GetEntityCoords(CurrentObject))
    local ground, z = GetGroundZFor_3dCoord(x, y, z, 0)
    SetEntityCoords(CurrentObject, x, y, z)

    return {x = x, y = y, z = z}
end

SelectCartItem = function (data)
    StopPlacement()

    if data ~= nil then
        StartPlacement(data)
    end
end

AddToCart = function (data)
    print('1')
    local item = {
        label = data.label,
        object = data.object,
        price = data.price,
        entity = CurrentObject,
        position = GetEntityCoords(CurrentObject),
        rotation = GetEntityRotation(CurrentObject),
        type = data.type,
    }
    
    Cart[CurrentObject] = item

    SendNUIMessage({
        action = "addToCart",
        data = item
    })

    StopPlacement()
    CurrentObject = nil
end

RemoveFromCart = function (data)
    local item = data

    if item ~= nil then
        DeleteEntity(item.entity)

        SendNUIMessage({
            action = "removeFromCart",
            data = item
        })

        Cart[data.entity] = nil
    end
end

UpdateCartItem = function (data)
    local item = Cart[data.entity]

    if item ~= nil then
        item = data
    end
end

ClearCart = function (self)
    for _, v in pairs(Cart) do
        DeleteEntity(v.entity)
    end

    Cart = {}
    SendNUIMessage({
        action = "clearCart"
    })
end

BuyCart = function (self)
    local items = {}
    local totalPrice = 0

-- If the cart is empty, return notify
    if not next(Cart) then
        Framework[Config.Notify].Notify("Your cart is empty", "error")
        return
    end
    
    -- seperate loop to get total price so it doesnt have to do all that math for no reason
    for _, v in pairs(Cart) do
        totalPrice = totalPrice + v.price
    end

    PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.money.cash < totalPrice and PlayerData.money.bank < totalPrice then
    Framework[Config.Notify].Notify("You don't have enough money!", "error")
        return
    end

    for _, v in pairs(Cart) do

        local offsetPos = {
            x = math.floor((v.position.x - shellPos.x) * 10000) / 10000,
            y = math.floor((v.position.y - shellPos.y) * 10000) / 10000,
            z = math.floor((v.position.z - shellPos.z) * 10000) / 10000,
        }
        
        local id = tostring(math.random(100000, 999999)..storeId)

        items[#items + 1] = {
            id = id,
            object = v.object,
            label = v.label,
            position = offsetPos,
            rotation = v.rotation,
            type = v.type,
        }
    end

    TriggerServerEvent("ps-housing:server:buyFurniture", storeId, furnitures, items, totalPrice)

    ClearCart()
end

SetHoverDistance = function (data)
    HoverDistance = data + 0.0
end

HoverIn = function (data)
    if HoverObject then
        local tries = 0
        while DoesEntityExist(HoverObject) do
            SetEntityAsMissionEntity(HoverObject, true, true)
            DeleteEntity(HoverObject)
            Wait(50)
            tries = tries + 1
            if tries > 25 then
                break
            end
        end

        HoverObject = nil
    end

    local object = data.object and joaat(data.object) or nil
    if object == nil then return end
    lib.requestModel(object)
    if HoverObject then return end
    HoverObject = CreateObject(object, 0.0, 0.0, 0.0, false, false, false)
    CurrentCameraLookAt =  Freecam:GetTarget(HoverDistance)
    local camRot = Freecam:GetRotation()

    SetEntityCoords(HoverObject, CurrentCameraLookAt.x, CurrentCameraLookAt.y, CurrentCameraLookAt.z)
    FreezeEntityPosition(HoverObject, true)
    SetEntityCollision(HoverObject, false, false)
    SetEntityRotation(HoverObject, 0.0, 0.0, camRot.z)

    IsHovering = true
    while IsHovering do
        local rot = GetEntityRotation(HoverObject)
        SetEntityRotation(HoverObject, rot.x, rot.y, rot.z + 0.1)
        Wait(0)
    end
end

HoverOut = function (self)
    if HoverObject == nil then return end
    if HoverObject and HoverObject ~= 0 then
        local tries = 0
        while DoesEntityExist(HoverObject) do
            SetEntityAsMissionEntity(HoverObject, true, true)
            DeleteEntity(HoverObject)
            Wait(50)
            tries = tries + 1
            if tries > 25 then
                break
            end
        end
        HoverObject = nil
    end
    IsHovering = false
end

SelectOwnedItem = function (data)
    StopPlacement()
    if data ~= nil then
        StartPlacement(data)
    end
end

RemoveOwnedItem = function (data)
    local item = data

    if item ~= nil then
        SendNUIMessage({
            action = "removeOwnedItem",
            data = item
        })

        TriggerServerEvent("ps-housing:server:removeFurniture", storeId, furnitures, item.id)
    end
end

RegisterNUICallback("previewFurniture", function(data, cb)
	StartPlacement(data)
	cb("ok")
end)

RegisterNUICallback("moveObject", function(data, cb)
    MoveObject(data)
    cb("ok")
end)

RegisterNUICallback("rotateObject", function(data, cb)
    RotateObject(data)
    cb("ok")
end)

RegisterNUICallback("stopPlacement", function(data, cb)
    StopPlacement()
    cb("ok")
end)

RegisterNUICallback("setObjectAlpha", function(data, cb)
    SetObjectAlpha(data)
    cb("ok")
end)

RegisterNUICallback("hideUI", function(data, cb)
    CloseMenu()
	cb("ok")
end)

RegisterNUICallback("freecamMode", function(data, cb)
    FreecamMode(data)
    cb("ok")
end)

RegisterNUICallback("placeOnGround", function(data, cb)
    local coords = PlaceOnGround()
    cb(coords)
end)

RegisterNUICallback("selectCartItem", function(data, cb)
    SelectCartItem(data)
    cb("ok")
end)

RegisterNUICallback("addToCart", function(data, cb)
    AddToCart(data)
    cb("ok")
end)

RegisterNUICallback("removeCartItem", function(data, cb)
    RemoveFromCart(data)
    cb("ok")
end)

RegisterNUICallback("updateCartItem", function(data, cb)
    UpdateCartItem(data)
    cb("ok")
end)

RegisterNUICallback("buyCartItems", function(data, cb)
    BuyCart()
    cb("ok")
end)

RegisterNUICallback("hoverIn", function(data, cb)
    HoverIn(data)
    cb("ok")
end)

RegisterNUICallback("hoverOut", function(data, cb)
    HoverOut()
    cb("ok")
end)

RegisterNUICallback("setHoverDistance", function(data, cb)
    SetHoverDistance(data)
    cb("ok")
end)

RegisterNUICallback("selectOwnedItem", function(data, cb)
    SelectOwnedItem(data)
    cb("ok")
end)

RegisterNUICallback("removeOwnedItem", function(data, cb)
    RemoveOwnedItem(data)
    cb("ok")
end)

RegisterNUICallback("showNotification", function(data, cb)
    Framework[Config.Notify].Notify(data.message, data.type)
    cb("ok")
end)




exports("LoadFurniture", LoadFurniture)

exports("UnloadFurnitures", UnloadFurnitures)