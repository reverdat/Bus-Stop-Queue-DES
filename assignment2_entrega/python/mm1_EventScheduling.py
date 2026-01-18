import math
import random
from enum import Enum
from dataclasses import dataclass, field
import heapq 

class EventType(Enum):
    ARRIVAL = 1
    SERVICE = 2

class ServerState(Enum):
    FREE = 0
    BUSY = 1

@dataclass(order=True) # order=True allows direct comparison for sorting
class Event:
    time: float
    type: EventType = field(compare=False)
    client_id: int = field(compare=False)

def random_exponential(rate_lambda):
    u = random.random()
    return -(1 / rate_lambda) * math.log(u)

def run_simulation(lam: float, mu: float, sim_duration: float):
    assert lam > 0, "Lambda must be positive"
    assert mu > 0, "Mu must be positive"

    current_time: float = 0.0
    state = ServerState.FREE
    num_clients_in_system: int = 0
    
    area_under_q: float = 0.0 
    last_event_time: float = 0.0
   
    # first arrival
    first_arrival = random_exponential(lam)
    events = []
    
    # heapq.heappush adds to the list and keeps it sorted by time
    heapq.heappush(events, Event(time=first_arrival, type=EventType.ARRIVAL, client_id=1))

    processed_events = 0
    client_counter = 1

    while events[0].time < sim_duration and events:
        # get event with lowest time
        current_event = heapq.heappop(events)
        current_time = current_event.time
        
        # Update Area statistics (Number of clients * duration since last event)
        area_under_q += num_clients_in_system * (current_time - last_event_time)
        last_event_time = current_time

        if current_event.type == EventType.ARRIVAL:
            num_clients_in_system += 1
            client_counter += 1
            
            # schedule next arrival
            next_arrival_time = current_time + random_exponential(lam)
            heapq.heappush(events, Event(next_arrival_time, EventType.ARRIVAL, client_counter))

            if state == ServerState.FREE:
                state = ServerState.BUSY
                service_time = random_exponential(mu)
                heapq.heappush(events, Event(current_time + service_time, EventType.SERVICE, current_event.client_id))

        elif current_event.type == EventType.SERVICE:
            num_clients_in_system -= 1
            
            if num_clients_in_system > 0: # people waiting in queue, serve inmediately
                service_time = random_exponential(mu)
                heapq.heappush(events, Event(current_time + service_time, EventType.SERVICE, 0))
            else:
                state = ServerState.FREE
        
        processed_events += 1

    avg_clients = area_under_q / current_time
    
    print(f"Simulation finished after {current_time:.2f} time units.")
    print(f"Total events processed: {processed_events}")
    print(f"Average clients in system (L): {avg_clients:.4f}")
    
    # Theoretical L for M/M/1 = rho / (1 - rho) where rho = lambda/mu
    rho = lam / mu
    if rho < 1:
        theoretical_L = rho / (1 - rho)
        print(f"Theoretical L: {theoretical_L:.4f}")
    else:
        print("System is unstable (Lambda > Mu), Theoretical L is infinity")

if __name__ == "__main__":
    run_simulation(lam=0.5, mu=1.0, sim_duration=10000)
