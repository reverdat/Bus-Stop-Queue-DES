"""
## domain.py

This module contains all entities
used as parameters or results for
the simulation.
"""

from typing import TypedDict, Literal, Optional


class Distribution(TypedDict):
    """
    Defines the possible implemented distributions
    to be used int the queue model.

    Parameters
    ----------
        One shall only specify parameters `(type, value)` if `type in ["constant", "exponential"]`
        or else `(type, min, max)` if `type == 'uniform'`.

        type: `Literal["constant", "exponential", "uniform"]`
            Name of the distribution. Only one of:
                - "constant": Degenerate r.v. with constant value.
                - "exponential": Exponential distribution.
                - "uniform": Continuous uniform distribution.
        value: `Optional[float]`
            Parameter of the distribution "exponential" or "constant".
        min: `Optional[float]`
            Left boundary of "uniform" distribution.
        max: `Optional[float]`
            Right boundary of "uniform" distribution.
    """

    type: Literal["constant", "exponential", "uniform"]
    value: Optional[float]
    min: Optional[float]
    max: Optional[float]


class SimConfig(TypedDict):
    """
    Enumeration of possible simulation parameters.

    Parameters
    ----------

        passenger_interarrival: `Distribution`
            Distribution of interarrival times
            of passangers into the system.

        bus_interarrival: `Distribution`
            Distribution of interarrival times
            of bus into the system.

        bus_capacity: `Distribution`
            Distribution which realizes the
            remaining capacity of the bus upon
            arriving to the stop.

        boarding_time: `Distribution`
            Distribution of time between
            boarding of two consecutive
            passangers into the bus.

        system_capacity: `int`
            Passanger capacity of the system.

        horizon: `float`
            Time horizon of the simulation.

    """

    passenger_interarrival: Distribution
    bus_interarrival: Distribution
    bus_capacity: Distribution
    boarding_time: Distribution
    system_capacity: int
    horizon: float


class SimResults(TypedDict):
    """
    System magnitudes resulting from the simulation.

    Parameters
    ----------

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

    duration: float
    average_clients: float
    lost_passengers: int
    processed_events: int
