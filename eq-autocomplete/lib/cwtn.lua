--[[
  CWTN class plugins (MQ2Eskay, MQ2Shaman, MQ2Bard...) each add one command named after the
  class: /shd, /shm, /brd... These are the commands their authors list publicly on each plugin's
  RedGuides page, in its Commands tab:

      https://www.redguides.com/community/resources/<page>/field?field=commands

  copied 2026-11-23. Nothing here is read from the plugins themselves. Each word is followed by
  what may come after it:
      :b          on | off
      :n          a number
      :m          a mode (MODES below)
      :o=a|b|c    one of these (<name> = a character's name)
      :s=a+b      these words in order
  A command shows up only while its plugin is loaded (engine:available).
]]
local M = {}

-- every page lists the same modes
M.MODES = { 'Manual', 'Assist', 'ChaseAssist', 'Vorpal', 'Tank', 'PullerTank', 'PullerAssist', 'SicTank', 'HunterTank' }

M.classes = {
    BER = {
        cmd = '/ber', plugin = 'MQ2BerZerker', page = 1018,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            UseBattleLeap:b UseBloodFury:b UseBraxi:b UseFrenzied:b UseIntimidate:b UseMangling:b
            UseOpener:b UsePet:b UseWarCry:b MGBWarCry:b ReportCA:b ReportAbility:b ReportCast:b
            ReportAutoDrop:b ShowTargeting:b ReportAassist:b
        ]],
    },
    BRD = {
        cmd = '/brd', plugin = 'MQ2Bard', page = 3162,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            ActiveDowntime:b AATimerOneEndMin:n Aura:n AutoCharmImmume:b AutoMezImmume:b BroadcastMez:b
            BYOS:b NukeManaMin:n RallyingEndurance:n RallyingMana:n ReflexiveMana:n UseBladedSong:b
            UseCacophony:b UseCharm:b UseDeftDance:b UseDot:b UseFlurryOfNotes:b UseFuneralDirge:b
            UseMezAoE:b UseMezST:b UseNuke:b UsePrankster:b UsePushInsult:b UseQuickTime:b UseRallyingCall:b
            UseRallyingSolo:b UseSelos:b UseSwarmPet:b UseThousandBlades:b Loadout:o=0|1|2|3|4
            Epic:o=0|1|2|3 ReportCA:b ReportAbility:b ReportCast:b ReportAutoDrop:b ShowTargeting:b
            ReportAassist:b DA AAInvis FlurryOfNotes
        ]],
    },
    BST = {
        cmd = '/bst', plugin = 'MQ2Bst', page = 1499,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b BYOS:b
            CheckForStuckGems:b CombatSummonPet:b DotHp:n DotHpNamed:n DotManaMin:n FeignAtAggro:n
            FeignAtHealth:n GroupShrink:b NukeManaMin:n PetShrink:b PetTauntToggle:b SummonFoodDrink:b
            SlowAll:b SlowNamed:b StandOnFeignAtHealth:n UseBandoSwap:b UseFeign:b UseMending:b UseParagon:b
            UseSnare:b UseSow:b MAHeal:n GroupHeal:n SelfHeal:n FocusedParagonEnd:n FocusedParagonMana:n
            ParagonEnd:n ParagonMana:n ReportCA:b ReportAbility:b ReportCast:b ReportAutoDrop:b
            ShowTargeting:b ReportAassist:b
        ]],
    },
    CLR = {
        cmd = '/clr', plugin = 'MQ2Cleric', page = 1498, aliases = { '/cleric' },
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            BattleMode:b BYOS:b CheckForStuckGems:b UseCures:b KeepHotUp:b UseMelee:b UseCelestialRegen:b
            UseDivineIntervention:b UseHand:b UseRetort:b UseRez:b UseDivineRez:b UseEpicRez:b UseRezStick:b
            UseSymbol:b UseVie:b UseWardAA:b UseXTargetBuffing:b UseXTargetHealing:b UseYaulp:b
            MaQuickHeal:n NonMaQuickHeal:n MADissident:n NonMADissident:n MAPromise:n NonMAPormise:n
            MAIntervention:n NonMaIntervention:n MAHealsHeals:n NonMAHealsHeals:n ReportCA:b ReportAbility:b
            ReportCast:b ReportAutoDrop:b ShowTargeting:b ReportAassist:b GHBuffBot:b GHBuffSilent:b
            GHBuffGuildOnly:b BuffRequestPhrase:o=<name>
        ]],
    },
    DRU = {
        cmd = '/dru', plugin = 'MQ2Druid', page = 2587,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            DisplayPortalUI:b SummonFoodDrink:n UseAASnare:b UseAura:b UseBlessingOfTunare:b UseBifold:b
            UseCharm:b UseCheetah:b MemCureAll:b MemGroupCureAll:b UseDot:b UseDS:b UseGrowth:b UseMelee:b
            UseNatureAAs:b UseNatureReaction:b UseNuke:b UseOfRo:b UsePreincarnation:b UseRegen:b
            UseReptile:b UseRez:b UseRezCall:b UseRezStick:b UseSeasonsWrath:b UseSkin:b UseSkinToPlant:b
            UseSwarmPet:b UseXTargetBuffing:b UseXTargetHealing:b DotHp:n DotHpNamed:n DotManaMin:n
            DurationHealMA:n DurationHealNotMA:n HealsHealsMA:n HealsHealsNotMA:n NukeManaMin:n PromHealMA:n
            PromNotMA:n AAInvis:o=Camo GroupInvis:o=GroupCamo Egress Exodus Gate SoE LoadOut:o=0|1|2
            PortSelf:o=<name> PortGroup:o=<name> Zephyr:o=Push|<name> Succor:o=<name> Evac:o=<name>
        ]],
    },
    ENC = {
        cmd = '/enc', plugin = 'MQ2Enchanter', page = 1612,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer DoCampfire CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b UpdateWinTitle:b StickSelection:o=0|1|2|3|4|5|6|7|8|9
            SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b aura AutoMezImmune:b BroadcastMez:b
            AutoCharmImmune:b CharmImmune:o=<name> UnCharmImmune:o=<name> InterruptForMez:b
            MezImmune:o=<name> UnMezImmune:o=<name> RemoveAuras UseCharm:b UseChaotic:b UseEradicate:b
            UseDot:b UseHaste:b UseMelee:b UseMez:b UseMindOverMatter:b UseNightsTerror:b UseNuke:b
            UsePhantasmal:b UseReplication:b UseShieldOfFate:b UseSlow:b UseTash:b SumAzureAt:n UseAzureAt:n
            SumSanguineAt:n UseSanguineAt:n GatherManaAt:n ReportCA:b ReportAbility:b ReportCast:b
            ReportAutoDrop:b ShowTargeting:b ReportAassist:b
        ]],
    },
    MAG = {
        cmd = '/mag', plugin = 'MQ2Mage', page = 2134,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer DoCampfire CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b
            UpdateWinTitle:b UseStick:b UseSwimFix:b UseGlyph:b UseProgressiveSpell:b BYOS:b CastFire:b
            CastMagic:b CombatSummonPet:b DeleteTrash:b GatherCapabilityAt:n ModRod NukeManaMin:n
            PetTauntToggle:b PetType:o=0|1|2|3|4|5 PetShrink:b UseCombatGather:b UseDS:b UseEradicate:b
            UseGroupModRod:b UseMalo:b UseMaloAoE:b UseMelee:b UseMinion:b UseNuke:b UseParadox:b
            UsePetWeapons:b UseServant:b UseShieldOfFate:b UseSkinDS:b UseSwarmPet:b UseVeilDS:b
            Coth:o=<name> GCoth:o=<name> ReportCA:b ReportAbility:b ReportCast:b ReportAutoDrop:b
            ShowTargeting:b ReportAassist:b
        ]],
    },
    MNK = {
        cmd = '/mnk', plugin = 'MQ2Monk', page = 1287, aliases = { '/monk' },
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            UseFeign:b UseBandoSwap:b MendAt:n FeignAtAggro:n FeignAtHealth:n UseIntimidate:b
            StandOnFeignAtHealth:n UseCures UseDisarm UseTigerClaw SwiftTailsEnd:n ReportCA:b
            ReportAbility:b ReportCast:b ReportAutoDrop:b ShowTargeting:b ReportAassist:b
        ]],
    },
    NEC = {
        cmd = '/nec', plugin = 'MQ2Necro', page = 2585,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            AutoMezImmume:b AutoSummonRemains:b BroadcastMez:b BYOS:b CheckForStuckGems:b CombatSummonPet:b
            KeepSynergy:b MemParox:b PetShrink:b PetTauntToggle:b PetType:o=0|1|2|Rogue|Warrior|Highest
            RaidSwapDots:b UseAASnare:b UseCharm:b UseDotSnare:b UseEradicate:b UseFeign:b UseFleshToVenom:b
            UseGatheringDusk:b UseGroupManaTap:b UseIgniteBones:b UseLich:b UseMez:b UseMuramRobe:b
            UseNuke:b UseRez:b UseRune:b UseSwarmPet:b UseScent:b UseShieldOfFate:b StandOnFeignAtHealth:n
            SpyrePyreDotCount:n SynergyDotCount:n NukeManaMin:n PetHeal:n LifeTap:n DotHp:n DotHPNamed:n
            DotManaMin:n FeignAtAggro:n FeignAtHealth:n ReportCA:b ReportAbility:b ReportCast:b
            ReportAutoDrop:b ShowTargeting:b ReportAassist:b
        ]],
    },
    PAL = {
        cmd = '/pal', plugin = 'MQ2Paladin', page = 2586,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            AATimerTwo:o=0|1|2|disruptive|divine|force BYOS:b HealsMA:n HealsNotMA:n MemSplash:b
            SplashCureOnly:b UseActOfValor:b UseCures:b UseBrells:b UseDisarm:b UseDivineCall:b
            UseHallowed:b UseHeroicLeap:b UseLayOnHands:b UseMarrsGift:b MarrsGiftEnd:n MarrsGiftMana:n
            UseMarrsSalv:b UsePenitence:b UseProjection:b UseRemorseFallen:b UseRez:b UseRezStick:b
            UseStanceBuff:b UseSymbol:b UseXTargetBuffing:b UseXTargetHealing:b
        ]],
    },
    RNG = {
        cmd = '/rng', plugin = 'MQ2Ranger', page = 2909,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:b
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            AATimer5:o=0|1 UseAtkHPBuff:b UseAuspice:b MGBAuspice:b UseBeza:b UseBifold:b UseDisarm:b
            UseDot:b UseEntrap:b UseEntropy:b UseRanged:b UseRegen:b UseScarletCheetah:b UseShoutCombo:b
            UseSwarmPet:b DotManaMin:n MAHeal:n GroupHeal:n NukeManaMin:n ReportCA:b ReportAbility:b
            ReportCast:b ReportAutoDrop:b ShowTargeting:b ReportAassist:b AAInvis:o=Camo AALev
            GroupInvis:o=GroupCamo SoE Gate
        ]],
    },
    ROG = {
        cmd = '/rog', plugin = 'MQ2Rogue', page = 1084,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            AutoCorpseGrab:b DebugCorpse UseDisarm:b ExeIsBurn:b UseHideSneak:b UseIntimidate:b
            UseLigamentSlice:b UseOpener:b UsePet:b ReportCA:b ReportAbility:b ReportCast:b ReportAutoDrop:b
            ShowTargeting:b ReportAassist:b
        ]],
    },
    SHD = {
        cmd = '/shd', plugin = 'MQ2Eskay', page = 1153,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            AutoSummonRemains:b BYOS:b CheckForStuckGems:b DotManaMin:n FeignAtAggro:n FeignAtHealth:n
            Lifetap:n PetShrink:b UseInsidious:b StandOnFeignAtHealth:n UseAASnare:b UseBeza:b UseDisarm:b
            UseDisruption:b UseFeign:b UseHatesAttraction:b UseLifetap:b UsePet:b UseSwarmPet:b UseTorrent:b
            UseVoiceOfThule:b ReportCA:b ReportAbility:b ReportCast:b ReportAutoDrop:b ShowTargeting:b
            ReportAassist:b
        ]],
    },
    SHM = {
        cmd = '/shm', plugin = 'MQ2Shaman', page = 1724,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer DoCampfire CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n LevelMin:n LevelMax:n
            PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on AutoAssistAt:n AutoDismount:b
            AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n BeepOnNamed:b BurnCount:n
            BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow ForceAlliance:b UseAlliance:b
            UseCures:b UpdateWinTitle:b StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b
            UseSwimFix:b UseGlyph:b Loadout:o=0|1|2 BYOS CheckForStuckGems:b MemCureAll:b ShmEpic:o=0|1|2
            SummonFoodDrink:b UseAncestralAid:b UseAttentiveSpirit:b UseAvatar:b UseCheetah:b
            UseCanniSpell:b UseDot:b UseFocus:b UseGroupShrink:b UseGrowth:b UseHaste:b UseNuke:b UseMalo:b
            UseMaloAoE:b UsePet:b UsePreincarnation:b UseRegen:b UseResponsiveSpirit:b UseRez:b UseRezCall:b
            UseRezStick:b UseSlow:b UseSlowAoE:b UseSow:b UseSpiritCall:b UseSquall:b UseVisionaryUnity:b
            UseXTargetBuffing:b UseXTargetHealing:b CanniAAMana:n CanniSpellMana:n DotManaMin:n DotHp:n
            DotHPNamed:n ManaAAConversion:n MendingMA:n MendingNotMA:n NukeManaMin:n RecklessMA:n
            RecklessNotMA:n STHoTMA:n STHoTNotMA:n ReportCA:b ReportAbility:b ReportCast:b ReportAutoDrop:b
            ShowTargeting:b ReportAassist:b GHBuffBot:b GHBuffSilent:b GHBuffGuildOnly:b
            BuffRequestPhrase:o=<name>
        ]],
    },
    WAR = {
        cmd = '/war', plugin = 'MQ2War', page = 1254,
        words = [[
            help show hide toggleui reload ShowSettings missing pause:b mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampfire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HpMedStart:n HpMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp debugpull:s=on+once debugduringpull:o=on
            AutoAssistAt:n AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n
            BeepOnNamed:b BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow
            ForceAlliance:b UseAlliance:b AllianceBurn:b UpdateWinTitle:b
            StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UseStick:b UseSwimFix:b UseGlyph:b
            UseBattleLeap:b UseDicho:b UseDisarm:b UseExpanse:b UseFortitude:b UsePhantom:b UsePrecision:b
            UseProjection:b UseGrasp:b UseSnare:b ReportCA:b ReportAbility:b ReportCast:b ReportAutoDrop:b
            ShowTargeting:b ReportAassist:b
        ]],
    },
    WIZ = {
        cmd = '/wiz', plugin = 'MQ2Wizard', page = 2932,
        words = [[
            Help Show Hide Toggleui Reload ShowSettings Missing Pause:b Mode:m RaidMode:b
            RaidAssistNum:o=1|2|3|<name> CampRadius:n DisablePullAbility:b Radius:n zRadius:n zHigh:n zLow:n
            CampOverlapBuffer:n DoCampFire:b CampfireDistance:n Ignore Unignore ShowIgnore
            GroupWatch:o=0|1|2|3|4 HPMedStart:n HPMedEnd:n ManaMedStart:n ManaMedEnd:n EndMedStart:n
            EndMedEnd:n LevelMin:n LevelMax:n PullArc:n GoToCamp DebugPull:s=on+once AutoAssistAt:n
            AutoDismount:b AutoRemoveInvul:b AutoStandOnFeign:b UseAoE:b AOECount:n BeepOnNamed:b
            BurnCount:n BurnAllNamed:b BurnAlways:b BurnNow ChaseDistance:n StopBurnNow UseAlliance:b
            ForceAlliance:b StickSelection:o=0|1|2|3|4|5|6|7|8|9 SwitchWithMA:b UpdateWinTitle:b UseStick:b
            UseSwimFix:b UseGlyph:b ReportCA:b ReportAbility:b ReportCast:b ReportAutoDrop:b
            ReportTargeting:b ReportAssist:b BYOS:b CastFire:b CastIce:b CastMagic:b NukeManaMin:n
            UseDamageShield:b UseDefensiveRune:b UseEradicate:b UseForceOfFlame:b UseForceOfIce:b
            UseForceOfWill:b UseGambit:b UseManaBurn:b UseMelee:b UseReflect:b UseRune:b UseShieldOfFate:b
            UseSilentCasting:b UseSwarmPet:b LoadOut:o=0|1 PortSelf:o=<name> PortGroup:o=<name>
            Translocate:o=Push|ReturnPush|<name> Succor:o=<name> Evac:o=<name>
        ]],
    },
}

-- short descriptions, from the same pages (by word, lower case)
M.desc = {
    ["aainvis"] = "Casts Innate Camoflage.",
    ["aalev"] = "Perfected Levitation",
    ["aatimer5"] = "Poison, Flaming",
    ["aatimeroneendmin"] = "Min amount of mana before using Vainglorious / Boastful.",
    ["aatimertwo"] = "Select what Timer Two AA you want to use.",
    ["activedowntime"] = "Should we keep up Lively Crescendo, Aria, War March / War Chorus, etc.",
    ["allianceburn"] = "Sets to only use Alliance during burn.",
    ["aoecount"] = "Use AoE at or above this number of mobs on XTarget",
    ["aura"] = "for information",
    ["autoassistat"] = "Sets the autoassistat value to the number provided. If no number is...",
    ["autocharmimmume"] = "Automatically add mobs to charmimmune list.",
    ["autocharmimmune"] = "adds mobs to charm immune automatically",
    ["autocorpsegrab"] = "Sets if you want to automatically corpse drag group members if they...",
    ["autodismount"] = "Automatically dismount from your horse",
    ["automezimmume"] = "Automatically add mobs to mezimmune list",
    ["automezimmune"] = "try and automatically add mobs to mez immune.",
    ["autoremoveinvul"] = "Automatically remove \"Touch of the Divine\" and similar",
    ["autostandonfeign"] = "Sets if you want the plugin to automatically stand if you are Feigning",
    ["autosummonremains"] = "Sets if you want to auto summon your group members",
    ["battlemode"] = "Sets if you want to do \"battle mode\" using contra instead of...",
    ["beeponnamed"] = "Beeps on named (when in a tank mode)",
    ["broadcastmez"] = "broadcasts mez usage (automagical eqbc/dannet detection)",
    ["buffrequestphrase"] = "allows you to change the request phrase",
    ["burnallnamed"] = "Sets using BurnAllNamed to the provided value.",
    ["burnalways"] = "Sets if you should always burn if a burn is up.",
    ["burncount"] = "Uses Burn at or above this number of mobs on XTarget",
    ["burnnow"] = "will force a burn.",
    ["byos"] = "Sets if you want to \"Bring Your Own Spells\" and handle your own buffs",
    ["campfiredistance"] = "Create a new campfire if campfire is more than this distance from...",
    ["campoverlapbuffer"] = "is the distance out of Camp to help group members (assigned puller...",
    ["campradius"] = "Sets the campradius to the value provided. If no value is provided it...",
    ["canniaamana"] = "the mana value you want to use your canni AA at",
    ["cannispellmana"] = "the mana value you want to use your canni spell at",
    ["castfire"] = "Toggle to cast fire spells or not (does not change spell loadout)",
    ["castice"] = "Casts Ice; doesn't adjust loadout",
    ["castmagic"] = "Toggle to cast magic spelsl or not (does not change spell loadout)",
    ["charmimmune"] = "Adds your target (or by name) to the mez immune list",
    ["chasedistance"] = "the distance at which you would like to move to your MA.",
    ["checkforstuckgems"] = "Sets if you want to try and \"unstick\" your spell gems - this will...",
    ["combatsummonpet"] = "Sets if you want to resummon a pet, buff it, and put your gems back...",
    ["coth"] = "Will use your AA Call of the hero on <name>, or try and use the Call...",
    ["da"] = "If you have Group DA / Self DA memorized, you will use it ASAP.",
    ["debugcorpse"] = "this will cycle through our corpse grabbing routine once and tell you...",
    ["debugduringpull"] = "this will tell you what is happening as you're pulling.",
    ["debugpull"] = "this will do 1 cycle of all the mobs and tell you why it isn't...",
    ["deletetrash"] = "Will delete Pouch of Quellious and non-dmg summoned pet weapons.",
    ["disablepullability"] = "allows you to disable the assigned pull ability",
    ["displayportalui"] = "Display the Portal UI.",
    ["docampfire"] = "Turns on dropping a campfire",
    ["dothp"] = "The max health your normal target will have for you to use your dots...",
    ["dothpnamed"] = "The max health your named target will have for you to use your dots...",
    ["dotmanamin"] = "Sets the minimum mana % you want to have before using dots (including...",
    ["durationhealma"] = "MA health % to cast Duration Heals.",
    ["durationhealnotma"] = "Non-MA health % to cast Duration Heals.",
    ["egress"] = "Uses Egress self evac AA.",
    ["endmedend"] = "percentage of endurance you want to stop waiting at.",
    ["endmedstart"] = "percentage of endurance you want to start waiting at.",
    ["epic"] = "0 is Never, 1 is During Burns, 2 is Combat, 3 is Wait for Shaman Epic",
    ["evac"] = "Evac.",
    ["exeisburn"] = "Sets if you want Executioner line to be a burn or not.",
    ["exodus"] = "Uses Exodus Group Evac AA.",
    ["feignataggro"] = "Sets the aggro value to use Feign if you have UseFeign on (and you...",
    ["feignathealth"] = "Sets the health value to use Feign if you have UseFeign on (and you...",
    ["flurryofnotes"] = "Use \"Flurry Of Notes\" on demand",
    ["focusedparagonend"] = "Sets the endurance value to use Focused Paragon",
    ["focusedparagonmana"] = "Sets the mana value to use Focused Paragon",
    ["forcealliance"] = "Force the plugin to use the character's alliance",
    ["gate"] = "Uses Gate AA.",
    ["gathercapabilityat"] = "mana value at which to use your Gather Capability Line",
    ["gathermanaat"] = "What mana % to use Gather Mana.",
    ["gcoth"] = "Will try and use your group call of the heros spell on <name>",
    ["ghbuffbot"] = "Toggles the Guild Hall Buff Bot Functionality",
    ["ghbuffguildonly"] = "If on, will require the \"requester\" to also be a member of your guild.",
    ["ghbuffsilent"] = "If on, will never send anyone a tell.",
    ["gotocamp"] = "runs back to your camp (like if you were in sictank mode)",
    ["groupheal"] = "Sets the value you want to use your heal on group members",
    ["groupinvis"] = "Casts Shared Camoflage.",
    ["groupshrink"] = "Sets if you want to use your group shrink AA",
    ["groupwatch"] = "Everyone, Healer, CC&Healer, Self, Cleric Only",
    ["healshealsma"] = "MA health % to cast Heals Heals (spell category -> Sub Category).",
    ["healshealsnotma"] = "Non-MA health % to cast Heals Heals (spell category -> Sub Category).",
    ["healsma"] = "Health value to heal the MA.",
    ["healsnotma"] = "Non-MA Health value.",
    ["help"] = "shows the help menu",
    ["hide"] = "Hides the CWTN UI window",
    ["hpmedend"] = "percentage of health you want to stop waiting at.",
    ["hpmedstart"] = "percentage of health you want to start waiting at.",
    ["ignore"] = "adds your target to the pullignores.ini file in your release folder -...",
    ["interruptformez"] = "Interrupts non-mez spells if it needs to cast mez.",
    ["keephotup"] = "Sets if you want to keep HoTs up while you have...",
    ["keepsynergy"] = "Will recast our synergy spell if we meet our SynergyDotCount and we...",
    ["levelmax"] = "Where # is the maximum level NPC you want to pull.",
    ["levelmin"] = "Where # is the lowest level NPC you want to pull.",
    ["lifetap"] = "Sets the health value to use your lifetap spells at - defaulted 100.",
    ["loadout"] = "healing, hybrid, dps",
    ["madissident"] = "Sets your MA Dissident/Undying Heal threshold",
    ["maheal"] = "Sets the value you want to use your heal on MA",
    ["mahealsheals"] = "sets your MAHealsHeals heal threshold",
    ["maintervention"] = "Sets your MA Intervention heal threshold",
    ["manaaaconversion"] = "Mana threshold to use Spiritual Channeling while burning.",
    ["manamedend"] = "percentage of mana you want to stop waiting at.",
    ["manamedstart"] = "percentage of mana you want to start waiting at.",
    ["mapromise"] = "Sets your MA Promise heal threshold",
    ["maquickheal"] = "Sets your MA Quick Heal threshold",
    ["marrsgiftend"] = "Endurance % you want to Marr's Gift at.",
    ["marrsgiftmana"] = "Mana % you want to Marr's Gift at.",
    ["memcureall"] = "Will memorize your \"Cure All\" line",
    ["memgroupcureall"] = "Memorizes GroupCureAll (Can not have both CureAll and GroupCureAll).",
    ["memparox"] = "Will memorize our paradox spell if we have one (dicho, dissi...",
    ["memsplash"] = "Memorize your splash line.",
    ["mendat"] = "Sets what health value you want to mend at.",
    ["mendingma"] = "the health value of MA you want to use the mending line",
    ["mendingnotma"] = "the health value of Non-MAs you want to use the mending line",
    ["mezimmune"] = "Adds your target to the mez immune list",
    ["mgbauspice"] = "Use MGB when you Auspice.",
    ["mgbwarcry"] = "MGB the warcry line while in raidmode",
    ["missing"] = "Shows what spells/tomes/abilities you are missing",
    ["mode"] = "Sets the plugin's mode (0-8)",
    ["modrod"] = "This will force mq2mage to cast the Modulation Shard AA, despite...",
    ["nonmadissident"] = "Sets your Non-MA Dissident/Undying Heal threshold",
    ["nonmahealsheals"] = "sets your Non-MA HealsHeals threshold",
    ["nonmaintervention"] = "Sets your Non-MA Intervention heal threshold",
    ["nonmapormise"] = "Sets your Non-MA Promise heal threshold",
    ["nonmaquickheal"] = "Sets your Non-MA Quick Heal threshold",
    ["nukemanamin"] = "The minimum mana you want to use your nukes",
    ["paragonend"] = "Sets the endurance value to use Paragon",
    ["paragonmana"] = "Sets the mana value to use Paragon",
    ["pause"] = "Pauses the plugin from doing anything",
    ["petheal"] = "Pet health value to heal.",
    ["petshrink"] = "sets if you want to try and shrink your pet.",
    ["pettaunttoggle"] = "Sets if you want to turn auto toggle pet taunt depending on your...",
    ["pettype"] = "PetType [0, 1, 2, 3, 4, 5 : fire, earth, water, air, monster, highest]",
    ["portgroup"] = "Stuff.",
    ["portself"] = "Stuff.",
    ["promhealma"] = "MA health % to cast Promised Heals.",
    ["promnotma"] = "Non-MA health % to cast Promised Heals.",
    ["pullarc"] = "Sets an arc in the direction of your camp heading to the degrees...",
    ["radius"] = "This is your pull radius",
    ["raidassistnum"] = "Sets if you should use Raid Assist 1, 2, or 3 or person by name when...",
    ["raidmode"] = "Sets if you want to use the Raid Assist instead of the Main Assist...",
    ["raidswapdots"] = "Will try and swap gems for extra dots while in raidmode.",
    ["rallyingendurance"] = "Endurance amount to use Rallying Call / Solo.",
    ["rallyingmana"] = "Mana amount to use Rallying Call / Solo.",
    ["recklessma"] = "the health value of MA you want to use the Reckless line at",
    ["recklessnotma"] = "the health value of Non-MAs you want to use the Reckless line at",
    ["reflexivemana"] = "Mana to use Reflexive line.",
    ["reload"] = "updates the skills/abilities/discs, updates clickies from the INI etc.",
    ["removeauras"] = "Removes current auras which will help you force recasting them (like...",
    ["reportaassist"] = "Reports when we grab assist target",
    ["reportability"] = "Reports Ability Usage",
    ["reportassist"] = "Reports when we grab assist target",
    ["reportautodrop"] = "Reports Auto Dropping",
    ["reportca"] = "Reports CA usage",
    ["reportcast"] = "Reports Spell Casts",
    ["reporttargeting"] = "Reports when we change target",
    ["selfheal"] = "Sets the value you want to use your heal on yourself",
    ["shmepic"] = "When to use epic - 0, 1, 2 for never, burn only, combat.",
    ["show"] = "Shows the CWTN UI window",
    ["showignore"] = "Outputs a list of NPC's being ignored. May show the previous zone if...",
    ["showsettings"] = "Will output all the settings and their current values (IE...",
    ["showtargeting"] = "Reports when we change target",
    ["slowall"] = "Sets if you want to try and slow everything",
    ["slownamed"] = "Sets if you want to try and slow named",
    ["soe"] = "Uses Spirit of Eagles AA.",
    ["splashcureonly"] = "Only use splash to cure.",
    ["spyrepyredotcount"] = "Amount of your dots on the mob to use Spyre, Pyre, and Muram robe...",
    ["standonfeignathealth"] = "Sets what Health value you want to stand on feign if you are...",
    ["sthotma"] = "the health value of MA you want to use STHoTs at",
    ["sthotnotma"] = "the health value of Non-MAs you want to use STHoTs at",
    ["stickselection"] = "changes what \"Stick Selection\" you want to use for assist modes.",
    ["stopburnnow"] = "will force stop \"burn now\".",
    ["succor"] = "Succor.",
    ["sumazureat"] = "What mana % minimum to summon Azure Crystal.",
    ["summonfooddrink"] = "Sets if you want to summon food and/or drink if you have less than 5...",
    ["sumsanguineat"] = "What mana % minimum to summon Sanguine Crystal.",
    ["swifttailsend"] = "endurance to use Swift Tails at.",
    ["switchwithma"] = "You cannot turn this off on the caster classes.",
    ["synergydotcount"] = "Amount of your dots on the mob before using synergy to keep up the...",
    ["toggleui"] = "Toggles visibility of the CWTN UI Window",
    ["translocate"] = "Zephyr/Push your target.",
    ["uncharmimmune"] = "Removes your target (or by name) from the charm immune list",
    ["unignore"] = "removes your target or typed name from your pullignores.ini file in...",
    ["unmezimmune"] = "Removes your target to the mez immune list",
    ["updatewintitle"] = "Sets if you want your EQ Window Title to get updated by the plugin",
    ["useaasnare"] = "Sets if you want to use your AA Snare",
    ["useactofvalor"] = "Use Act of Valor AA.",
    ["usealliance"] = "Sets if you should use Alliance or not.",
    ["useancestralaid"] = "Use Ancestral Aid",
    ["useaoe"] = "Sets UseAoE to the provided value.",
    ["useatkhpbuff"] = "Use AtkHPBuff line.",
    ["useattentivespirit"] = "Use \"Spirit\" line of buffs",
    ["useaura"] = "Use Druid Aura.",
    ["useauspice"] = "Use Auspice AA.",
    ["useavatar"] = "Use Avatar (you only do this 85 and below)",
    ["useazureat"] = "What mana % to use Azure Crystal.",
    ["usebandoswap"] = "Sets if you want to swap bandolier sets to proc Fists of Fury before...",
    ["usebattleleap"] = "If you should use Battle leap or not",
    ["usebeza"] = "Sets if you want to use Beza over Azia",
    ["usebifold"] = "UseBifold.",
    ["usebladedsong"] = "Use Bladed Song AA.",
    ["useblessingoftunare"] = "Use Blessing of Tunare.",
    ["usebloodfury"] = "Sets if you should use Blood Fury or not.",
    ["usebraxi"] = "Sets if you should use War Cry of the Baxi or not (This is a...",
    ["usebrells"] = "Use the Brells line of buffs.",
    ["usecacophony"] = "Use Cacophony AA.",
    ["usecannispell"] = "Memorize (for non byos) and use Cannibalize Spell line",
    ["usecelestialregen"] = "Use Celestial Regen during burn",
    ["usechaotic"] = "uses Chaotic Mez",
    ["usecharm"] = "Use Charm instead of pet",
    ["usecheetah"] = "Use Communion of Cheetah AA",
    ["usecombatgather"] = "Use Gather Capability while in combat",
    ["usecures"] = "uses self cure when possible.",
    ["usedamageshield"] = "Use low level damage shield - likely want this off at high level",
    ["usedefensiverune"] = "Use Defensive Rune (over Rune)",
    ["usedeftdance"] = "Use Deft Dance AA.",
    ["usedicho"] = "If you should use Dicho line or not",
    ["usedisarm"] = "Use Disarm skill",
    ["usedisruption"] = "Use Disruption line",
    ["usedivinecall"] = "Use Divine Call.",
    ["usedivineintervention"] = "Sets if you want to use the Divine Intervention lines",
    ["usedivinerez"] = "Sets if you want to use your Divine Rez.",
    ["usedot"] = "Use Dots",
    ["usedotsnare"] = "Will use a memorized Dot/Snare spell Snare. Does not automemorize it...",
    ["useds"] = "Use DS line of damage shield",
    ["useentrap"] = "Use AA Snare \"Entrap\".",
    ["useentropy"] = "Use Entropy AA to remove beneficial buffs.",
    ["useepicrez"] = "Sets if you want to use your 1.0 to rez.",
    ["useeradicate"] = "uses Eradicate AA.",
    ["useexpanse"] = "If you should use Expanse line or not",
    ["usefeign"] = "Sets if you want to use Feign lines",
    ["usefleshtovenom"] = "Use Flesh To Venom line. Would re-cast Mort Unity, or the spell if no...",
    ["useflurryofnotes"] = "Use Flurry Of Notes AA during burns.",
    ["usefocus"] = "Use Focus Lines",
    ["useforceofflame"] = "Use Force Of Flame AA",
    ["useforceofice"] = "Use Force Of Ice AA",
    ["useforceofwill"] = "Use Force Of Will AA",
    ["usefortitude"] = "If you should use Fortitude line or not",
    ["usefrenzied"] = "Sets if you should use Frenzied Resolve or not.",
    ["usefuneraldirge"] = "Use Funeral Dirge AA during burns.",
    ["usegambit"] = "Use Gambit line of spells over Harvest",
    ["usegatheringdusk"] = "Use your Gathering Dusk AA --- huge aggro.",
    ["useglyph"] = "Sets if you want to use the Glyph of Destruction line of Glyph's...",
    ["usegrasp"] = "If you should use Grapple line or not",
    ["usegroupmanatap"] = "Use the GroupManaTap spell line.",
    ["usegroupmodrod"] = "Use Group Mod Rod",
    ["usegroupshrink"] = "Use Group Shrink AA and Shrink spells to shrink group",
    ["usegrowth"] = "Use Growth line",
    ["usehallowed"] = "Use Hallowed AA.",
    ["usehand"] = "Sets if you want to use the \"Hand\" line of buffs (useful at lower...",
    ["usehaste"] = "Usage of haste",
    ["usehatesattraction"] = "Sets if you want to use Hate's Attraction",
    ["useheroicleap"] = "UseHeroicLeap.",
    ["usehidesneak"] = "Sets if you want to Hide/Sneak during downtime.",
    ["useignitebones"] = "Use the IgniteBones spell line. This will then try and keep undead...",
    ["useinsidious"] = "Memorize Insidious over AoEJolt",
    ["useintimidate"] = "Sets if you should use Intimidate or not.",
    ["uselayonhands"] = "Use Lay On Hands.",
    ["uselich"] = "Use the Lich spell line.",
    ["uselifetap"] = "Use Lifetaps - will still use lifetap to pull at lower lvl with this...",
    ["useligamentslice"] = "Sets if you should use LigamentSlice or not.",
    ["usemalo"] = "Use Malo AA (or spell)",
    ["usemaloaoe"] = "Wind of Malaise AA",
    ["usemanaburn"] = "Use Mana Burn during Burns",
    ["usemangling"] = "Replaces brutal disc with mangling and pushing down burns 1 tier.",
    ["usemarrsgift"] = "Use Marr's Gift AA.",
    ["usemarrssalv"] = "Use Marr's Salv.",
    ["usemelee"] = "Sets if you want to melee",
    ["usemending"] = "Sets if you want to mem/use the mending line",
    ["usemez"] = "Mez stuff",
    ["usemezaoe"] = "Use AoE Mez.",
    ["usemezst"] = "Use Single Target Mez.",
    ["usemindovermatter"] = "Use Mind Over Matter AA",
    ["useminion"] = "Use Exigent Minion clicky line",
    ["usemuramrobe"] = "Use Muram Robe during burn, taking SpirePyreDotCount into...",
    ["usenatureaas"] = "Use \"Nature of\" line of AA spells.",
    ["usenaturereaction"] = "Use Nature's Reaction.",
    ["usenightsterror"] = "Use Night's Terror",
    ["usenuke"] = "Turn off nukes",
    ["useofro"] = "Use Vortex of Ro AA.",
    ["useopener"] = "Use your Opener",
    ["useparadox"] = "Use Paradox like \"Grant Frostbound Paradox\"",
    ["useparagon"] = "Sets if you want to use Paragon",
    ["usepenitence"] = "Use penitence line over armor.",
    ["usepet"] = "Toggles on using swarm pet or not",
    ["usepetweapons"] = "Summon and hand out Pet Weapons to group members",
    ["usephantasmal"] = "Use Phantasmal Opponent",
    ["usephantom"] = "If you should use Phantom Aggressor or not",
    ["useprankster"] = "Use Lyrical Prankster Swarm Pet AA.",
    ["useprecision"] = "If you should use Precision line or not",
    ["usepreincarnation"] = "Use Preincarnation Spell AA",
    ["useprogressivespell"] = "Toggle the use of your progressive spell",
    ["useprojection"] = "If you should use Projection of Fury or not",
    ["usepushinsult"] = "Use T3/T6 push or non-push insults.",
    ["usequicktime"] = "Use QuickTime AA.",
    ["userallyingcall"] = "Use Rallying Call.",
    ["userallyingsolo"] = "Use Rallying Solo.",
    ["useranged"] = "Use Ranged instead of Melee.",
    ["usereflect"] = "Use the best reflection spell you have",
    ["useregen"] = "Use Regen line",
    ["useremorsefallen"] = "Use \"Stance\" buff line.",
    ["usereplication"] = "Use Mana Replication",
    ["usereptile"] = "Use the Reptile line of spells.",
    ["useresponsivespirit"] = "Use Responsive Spirit",
    ["useretort"] = "Sets if you want to use the \"Retort\" line of spells/tomes/abilities",
    ["userez"] = "Sets if you want to do rezzing.",
    ["userezcall"] = "Uses the \"Call of the Wild\" AA during the rez routine while in combat.",
    ["userezstick"] = "Sets if you want to use your rez stick.",
    ["userune"] = "Use the Rune buff line",
    ["usesanguineat"] = "What health % to use Sanguine Crystal.",
    ["usescarletcheetah"] = "Use Scarlet Cheetah AA.",
    ["usescent"] = "Use Scent of... AA line.",
    ["useseasonswrath"] = "Use Season's Wrath AA.",
    ["useselos"] = "Use Selo's AA.",
    ["useservant"] = "Use Exigent Servant clicky line",
    ["useshieldoffate"] = "Enables use of the Shield of Fate spell line",
    ["useshoutcombo"] = "Use ShoutCombo line of spells.",
    ["usesilentcasting"] = "Enables use of the Silent Casting AA during burns",
    ["useskin"] = "Use Skin / GroupSkin line of spells.",
    ["useskinds"] = "Use SkinDS line of damage shield",
    ["useskintoplant"] = "Use Skin to Plant line of spells.",
    ["useslow"] = "Slows",
    ["useslowaoe"] = "Uses SlowAoE AA",
    ["usesnare"] = "If you should use Snare or not",
    ["usesow"] = "Sets to use SoW line",
    ["usespiritcall"] = "Use Spirit Call AA during burn (swarm pet)",
    ["usesquall"] = "Use Squall",
    ["usestancebuff"] = "Use Remorse of the Fallen.",
    ["usestick"] = "Sets if you want the plugin to use MQ2MoveUtils to stick to a mob for...",
    ["useswarmpet"] = "Use your \"chattering bones\" AA during burn",
    ["useswimfix"] = "Will swim down to a mob to engage",
    ["usesymbol"] = "Sets if you want to use \"Symbols\" line of buffs",
    ["usetash"] = "Use Malo AA (or spell)",
    ["usethousandblades"] = "Use ThousandBlades",
    ["usetigerclaw"] = "uses Tiger Claw over dragon punch / tail rake;",
    ["usetorrent"] = "Sets if you want to memorize \"Torrent\" line over \"Bite\" line",
    ["useveilds"] = "Use Veil line of damage shield",
    ["usevie"] = "Sets if you want to use the \"Vie\" line of buffs",
    ["usevisionaryunity"] = "Use Visionary's Unity AA (chance to trigger swarm pets)",
    ["usevoiceofthule"] = "Sets if you want to use Voice of Thule AA",
    ["usewarcry"] = "Use WarCry line",
    ["usewardaa"] = "if you have usecures on you will use ward of purity, if usecures off...",
    ["usextargetbuffing"] = "Sets if you want to do XTarget Buffing (do not need to specify which...",
    ["usextargethealing"] = "Sets if you want to do XTarget Healing (do not need to specify which...",
    ["useyaulp"] = "Sets if you want to use Yaulp AA",
    ["zephyr"] = "Zephyr/Push your target.",
    ["zhigh"] = "This is your vertical pull radius above you",
    ["zlow"] = "This is your vertical pull radius below you",
    ["zradius"] = "This is your vertical pull radius",
}

-- what may follow a word, as grammar (see lib/grammar.lua); always optional: a setting typed
-- without a value makes the plugin print the current one
local function argNode(code)
    if code == 'b' then return { alt = { { 'on' }, { 'off' } }, o = 1 } end
    if code == 'n' then return { alt = { { { v = 'value' } } }, o = 1 } end
    if code == 'm' then
        local alts = {}
        for i, name in ipairs(M.MODES) do alts[i] = { { k = tostring(i - 1), d = name } } end
        return { alt = alts, o = 1 }
    end
    local options = code:match('^o=(.+)$')
    if options then
        local alts = {}
        for w in options:gmatch('[^|]+') do alts[#alts + 1] = { w == '<name>' and { v = 'name' } or w } end
        return { alt = alts, o = 1 }
    end
    local words = code:match('^s=(.+)$')
    if words then
        local seq = {}
        for w in words:gmatch('[^+]+') do seq[#seq + 1] = w end
        return { alt = { seq }, o = 1 }
    end
    return nil
end

---Every class command, in the shape of lib/commands.lua entries: {['/shd'] = {p, d, a, s, g}, ...}
function M.commands()
    local out = {}
    for _, c in pairs(M.classes) do
        local g = {}
        for item in c.words:gmatch('%S+') do
            local word, code = item:match('^([^:]+):?(.*)$')
            local seq = { { k = word, d = M.desc[word:lower()] } }
            seq[2] = argNode(code)
            g[#g + 1] = seq
        end
        out[c.cmd] = {
            p = c.plugin,
            d = 'CWTN class plugin ' .. c.plugin .. ' (commands from its RedGuides page)',
            a = c.aliases,
            s = { c.cmd .. ' <setting> [on | off | value]', c.cmd .. ' mode <0-8>' },
            g = g,
        }
    end
    return out
end

return M
