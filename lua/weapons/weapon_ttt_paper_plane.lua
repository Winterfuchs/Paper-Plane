AddCSLuaFile()

resource.AddFile("materials/vgui/ttt/paper_plane_icon.vmt")

local shouldBeLimitedStock = CreateConVar( "ttt_paper_plane_limited_stock", 1 , {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "Should it be limited stock in the shop?" )

if SERVER then
	util.AddNetworkString("ttt_paper_plane_register_thrower")
	util.AddNetworkString("ttt_paper_plane_update_team")
end

SWEP.HoldType = "normal"


if CLIENT then
   SWEP.PrintName = "Paper Plane"
   SWEP.Slot = 6

   SWEP.ViewModelFOV = 10

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "Follows the closest enemy nearby.\nWill explode on touch."
   };

   SWEP.Icon = "vgui/ttt/paper_plane_icon"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel          = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel         = "models/props_c17/suitcase_passenger_physics.mdl"

SWEP.DrawCrosshair      = false
SWEP.Primary.ClipSize       = 1
SWEP.Primary.DefaultClip    = 1
SWEP.Primary.Automatic      = true
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize     = 1
SWEP.Secondary.DefaultClip  = 1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Delay = 1.0

-- This is special equipment

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = false
SWEP.WeaponID = AMMO_PAPER_PLANE

SWEP.AllowDrop = true

SWEP.NoSights = true

function SWEP:PrimaryAttack()

	if not self:CanPrimaryAttack() then
	return end

	 self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

	 self:CreatePaperWing()
	 self:TakePrimaryAmmo ( 1 )
	 if SERVER then
		self:Remove()
	 end

end

function SWEP:DrawWorldModel()
	return false
end

SWEP.ENT = nil

function SWEP:CreatePaperWing()
	if SERVER then
		local ply = self.Owner
		local paper_plane = ents.Create("ttt_paper_plane_proj")
			if IsValid(paper_plane) and IsValid(ply) then
				local vsrc = ply:GetShootPos()
				local vang = ply:GetAimVector()
				local vvel = ply:GetVelocity()
				local vthrow = vvel + vang * 250
				paper_plane:SetPos(vsrc + vang * 50)
				paper_plane:SetAngles(ply:GetAimVector():Angle() + Angle(0, 180, 0))
				paper_plane:Spawn()
				paper_plane:SetThrower(ply)

				paper_plane:SetNWEntity("paper_plane_owner", ply)

				if TTT2 then
				local team = TEAMS[ply:GetTeam()]

				paper_plane.userdata = {
					team = ply:GetTeam()
				}
				timer.Simple( 0.1, function()
					net.Start("ttt_paper_plane_register_thrower")
					net.WriteEntity(paper_plane)
					net.WriteString(ply:GetTeam())
					net.Broadcast()
				end)
			end

				local phys = paper_plane:GetPhysicsObject()
					if IsValid(phys) then
						phys:SetVelocity(vthrow)
						phys:SetMass(200)
					end
					self.ENT = paper_plane
			end
	end
end


function SWEP:SecondaryAttack()
  if not self:CanSecondaryAttack() then return end
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay)
		if not IsFirstTimePredicted() then return end
end


function SWEP:OnRemove()
   if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
      RunConsoleCommand("lastinv")
   end
end

function SWEP:OnDrop()
	self:Remove()
end

if TTT2 then
	if SERVER then
		hook.Add("TTT2UpdateTeam", "tt2_paper_plane_team", function(ply, old, new)
			net.Start("ttt_paper_plane_update_team")
			net.WriteString(new)
			net.Send(ply)
		end)
	end
end
