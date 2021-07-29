AddCSLuaFile()
resource.AddFile( "models/props/c_paperplane/c_paperplane.mdl" )
resource.AddFile("materials/models/props/c_paperplane/c_paperplane_tex.vmt")

ENT.Type = "anim"

local shouldBeDestroyable = CreateConVar( "ttt_paper_plane_destroyable", 1 , {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "Should the paper plane be destoyable?" )
local paperPlaneHealth = CreateConVar( "ttt_paper_plane_health", 200 , {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "How much health should the paper plane have?" )
local renderHealthbar = CreateConVar( "ttt_paper_plane_render_healthbar", 0 , {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_LUA_SERVER}, "Should the paper plane render a healthbar?" )

AccessorFunc(ENT, "thrower", "Thrower")

function ENT:Initialize()
	self:SetModel("models/props/c_paperplane/c_paperplane.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetHealth(paperPlaneHealth:GetInt())
	if SERVER then
		util.SpriteTrail(self, 0, Color(255,0,0), false, 25, 1, 4, 1/(15+1)*0.5, "trails/laser.vmt")
	end

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableGravity(false)
	end
end

function ENT:Think()
	self:SearchPlayer()
	self:NextThink( CurTime() )
	return true
end

function ENT:SearchPlayer()
	if SERVER then
		local pos = self:GetPos();
		local sphere = ents.FindInSphere(pos, 5000)
		local playersInSphere = {}
		local thrower = self:GetThrower()

		for key, v in pairs(sphere) do
			if TTT2 then
				if v:IsPlayer() and v:Alive() and not v:IsSpec() and v:GetTeam() ~= thrower:GetTeam() then
					table.insert(playersInSphere, v)
				end
			elseif CR_VERSION then
				if v:IsPlayer() and v:Alive() and not v:IsSpec() and not v:IsSameTeam(thrower) then
					table.insert(playersInSphere, v)
				end
			else
				if v:IsPlayer() and v:GetRole() ~= thrower:GetRole() and v:Alive() and not v:IsSpec() then
			table.insert(playersInSphere, v)
				end
				end
		end

		local closestPlayer = self:GetClosestPlayer(self, playersInSphere)

		if (closestPlayer ~= nil) then
			local tracedata = {};
				tracedata.start = closestPlayer:GetShootPos();
				tracedata.endpos = self:GetPos();
				tracedata.filter = { self, closestPlayer };
				local tr = util.TraceLine(tracedata)
				if tr.HitPos == tracedata.endpos then
					local phys = self:GetPhysicsObject()
					phys:ApplyForceCenter((self:GetPos() - closestPlayer:GetShootPos())*-200 )
					phys:SetAngles((self:GetPos() - closestPlayer:GetShootPos()):Angle())
				end
		end
		table.Empty(playersInSphere)
	end
end

function ENT:GetClosestPlayer(entity, players)
	local pos = entity:GetPos()
	local closestPlayer = players[1]
	for k, v in pairs(players) do
		if (pos:Distance(v:GetPos()) < pos:Distance(closestPlayer:GetPos())) then
			closestPlayer = v
		end
	end
	return closestPlayer
end

function ENT:Touch( entity )
	if entity:IsPlayer() and entity ~= self:GetThrower() then
		local pos = self:GetPos()
		local inflictor = ents.Create("weapon_ttt_paper_plane")
		local dmgInfo = DamageInfo()

		dmgInfo:SetDamageType(DMG_BLAST)
		dmgInfo:SetAttacker(self:GetThrower())
		dmgInfo:SetInflictor(inflictor)
		dmgInfo:SetDamage(200)

		util.BlastDamageInfo( dmgInfo, pos, 150 )

		effect = EffectData()
		effect:SetOrigin(pos)
		effect:SetStart(pos)

		util.Effect("Explosion", effect, true, true)
		self:Remove()
	end
end

function ENT:OnTakeDamage(damage)
	if shouldBeDestroyable:GetBool() then
	 local dmg = self:Health() - damage:GetDamage()
	 self:SetHealth(dmg)

		if (self:Health() <= 0) then
			local pos = self:GetPos()
			local effect = EffectData()

			effect:SetStart(pos)
			effect:SetOrigin(pos)
			util.Effect("cball_explode", effect, true, true)
			self:Remove()
		end
	end
end

function ENT:Draw()
	if IsValid(self) then
		self:DrawModel()
		if renderHealthbar:GetBool() then
			local pos = self:GetPos() + Vector(0, 0, 20)
			local ang = Angle(0, LocalPlayer():GetAngles().y - 90, 90)
			surface.SetFont("Default")
			local width = 200 / 1.5

			cam.Start3D2D(pos, ang, 0.3)
				draw.RoundedBox( 5, -width / 2, -5, 200 / 1.5, 15, Color(255, 0, 0, 20) )
				draw.RoundedBox( 5, -width / 2 , -5, (self:Health() / paperPlaneHealth:GetInt() * 200) / 1.5, 15, Color(0, 255, 0, 120) )
				draw.SimpleText("Paper Plane", "ChatFont", 0, -5, Color(255,255,255,255), TEXT_ALIGN_CENTER)
			cam.End3D2D()
		end
	end
end

function OnHitThrower( victim, attacker )
	if (attacker:GetDamageType() == DMG_CRUSH) then
		if attacker:GetInflictor():GetClass() == "ttt_paper_plane_proj" then
			if (victim == attacker:GetInflictor():GetThrower()) then
				attacker:ScaleDamage( 0 )
			end
		end
	end
end
hook.Add( "EntityTakeDamage", "OnHitThrower", OnHitThrower )
