import Foundation

/// v141.6 (TestFlight, Bristol): a contract vehicle sounds only as it arrives or leaves, once per event. The app asks
/// `VehicleSoundLog.first(_:)` before it plays; an event that has already sounded never sounds again, whatever redraws,
/// rebuilds or re-renders the town (the prototype's `VEH_SND`).
public struct VehicleSoundEvent: Hashable, Sendable {
    public enum Moment: String, Sendable { case arrive, depart, scene }
    public var company: String
    public var region: RegionID
    public var moment: Moment
    /// The job's id for an arrival; the first day it may leave for a departure (one per finished job); 0 for the first
    /// offer's scene.
    public var ref: Int
    public var owner: ContractOwner?

    public init(company: String, region: RegionID, moment: Moment, ref: Int, owner: ContractOwner?) {
        self.company = company; self.region = region; self.moment = moment; self.ref = ref; self.owner = owner
    }
}

public struct VehicleSoundLog: Sendable {
    private var played = Set<VehicleSoundEvent>()
    public init() {}
    /// True the first time an event is offered, false ever after.
    public mutating func first(_ e: VehicleSoundEvent) -> Bool { played.insert(e).inserted }
}

extension GameState {
    /// The arrival of the job whose vehicle pulls in now (`contractDue`).
    public var contractArrivalEvent: VehicleSoundEvent? {
        contractDue.map { VehicleSoundEvent(company: company, region: region, moment: .arrive, ref: $0.id, owner: $0.owner) }
    }
    /// A finished job's vehicle leaving, once it may (`depart.from`) and hasn't started yet.
    public var contractDepartureEvent: VehicleSoundEvent? {
        guard contractConfig != nil, let d = local.contracts?.depart, d.leaving != true, day >= d.from else { return nil }
        return VehicleSoundEvent(company: company, region: region, moment: .depart, ref: d.from, owner: d.owner)
    }
    /// The first offer's scene: the offer's vehicle comes in once per region.
    public var contractSceneEvent: VehicleSoundEvent {
        VehicleSoundEvent(company: company, region: region, moment: .scene, ref: 0, owner: nil)
    }
}
