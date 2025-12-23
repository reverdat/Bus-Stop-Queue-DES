"""
## simulations.py

This module contains all simulation
functions implemented in the event_scheduling_bus
package
"""

from ._lib import eventSchedulingBus as _eventSchedulingBus

from .domain import SimConfig, SimResults, Distribution


def simulate_mmx1k_preentrega(
    passenger_interarrival_rate: float,
    bus_interarrival_rate: float,
    bus_capacity: int,
    k: int,
    horizon: float,
) -> dict:
    """
    Simulate a single trajectory of the bus stop as a
    $M/M^{[X]}/1/K$ queue. Bus capacity upon arrival
    $X$ is assumed to be a degenerate constant r.v.

    Parameters
    ----------

        passenger_interarrival_rate: `float`
            Distribution of interarrival times
            of passangers into the system.

        bus_interarrival_rate: `float`
            Distribution of interarrival times
            of bus into the system.

        bus_capacity: `int`
            Fixed capacity of the bus upon arrival to
            the stop.

        k: `int`
            Passanger capacity of the system.

        horizon: `float`
            Time horizon of the simulation.

    Returns
    -------

        sim_results: `dict`
            System magnitudes resulting from the simulation:

                duration: `float`
                    Total time elapsed in the simulation.

                average_clients: `float`
                    Average value of clients in the system.

                lost_passengers: `int`
                    Number of passengers that could not enter the system
                    due to max capacity.

                processed_events: `int`
                    Total number of events realized.

    """
    dist_pass_interarrival = Distribution(type="exponential", value=passenger_interarrival_rate, min=None, max=None)
    dist_bus_interarrival = Distribution(type="exponential", value=bus_interarrival_rate, min=None, max=None)
    dist_bus_capacity = Distribution(type="constant", value=bus_capacity, min=None, max=None)
    dist_boarding_time = Distribution(type="constant", value=1e-16, min=None, max=None)
    system_capacity = k
    horizon = horizon
    sim_config = SimConfig(
        passenger_interarrival=dist_pass_interarrival,
        bus_interarrival=dist_bus_interarrival,
        bus_capacity=dist_bus_capacity,
        boarding_time=dist_boarding_time,
        system_capacity=system_capacity,
        horizon=horizon,
    )

    sim_results = _eventSchedulingBus(sim_config)

    return sim_results
