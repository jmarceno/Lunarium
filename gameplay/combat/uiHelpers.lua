-- UI Helper Functions
local function showActionButtons(self)
    self.elements.attackButton.visible = true
    self.elements.skillButton.visible = true
    self.elements.itemButton.visible = true
    self.elements.defendButton.visible = true
end

local function hideActionButtons(self)
    self.elements.attackButton.visible = false
    self.elements.skillButton.visible = false
    self.elements.itemButton.visible = false
    self.elements.defendButton.visible = false
end

local function hideSelectionLists(self)
    self.elements.skillList.visible = false
    self.elements.itemList.visible = false
    self.elements.partySelectList.visible = false
    if self.elements.enemySelectList then
        self.elements.enemySelectList.visible = false
    end
end

local function showConfirmBackButtons(self, showConfirm, showBack)
    self.elements.confirmButton.visible = showConfirm or false
    self.elements.backButton.visible = showBack or false
end

local function hideAllUI(self)
    hideActionButtons(self)
    hideSelectionLists(self)
    showConfirmBackButtons(self, false, false)
end

return {
    showActionButtons = showActionButtons,
    hideActionButtons = hideActionButtons,
    hideSelectionLists = hideSelectionLists,
    showConfirmBackButtons = showConfirmBackButtons,
    hideAllUI = hideAllUI
}