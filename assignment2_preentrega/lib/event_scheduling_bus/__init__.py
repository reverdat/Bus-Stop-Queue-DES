"""
## event_scheduling_bus

This Python library implements an event-scheduling-based 
simulation of a bus stop based on a $M/M^{[X]}/1/K$ queue, 
with its backend implemented in Zig for high-performance.

This module imports all library entities into a single
namespace for convenience.
"""

from .domain import Distribution, SimConfig, SimResults
from .simulations import simulate_mmx1k_preentrega
