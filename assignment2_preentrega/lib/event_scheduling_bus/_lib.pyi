from typing import TypedDict, Literal, Optional
  
class Distribution(TypedDict):  
    type: Literal["constant", "exponential", "uniform"]  
    value: Optional[float]  
    min: Optional[float] 
    max: Optional[float]  
  
class SimConfig(TypedDict):  
    passenger_interarrival: Distribution  
    bus_interarrival: Distribution  
    bus_capacity: Distribution  
    boarding_time: Distribution  
    system_capacity: int  
    horizon: float  
  
class SimResults(TypedDict):  
    duration: float  
    average_clients: float  
    lost_passengers: int  
    processed_events: int

def eventSchedulingBus(config: SimConfig) -> SimResults: ...

