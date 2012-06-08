--------------------------------------------------------------------------------
-- NukeSim, a nuclear plant real-time simulation for educational purpose      --
-- Copyright (C) 2012  Alberto Franco                                         --
--                                                                            --
-- This program is free software: you can redistribute it and/or modify       --
-- it under the terms of the GNU General Public License as published by       --
-- the Free Software Foundation, either version 3 of the License, or          --
-- (at your option) any later version.                                        --
--                                                                            --
-- This program is distributed in the hope that it will be useful,            --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of             --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              --
-- GNU General Public License for more details.                               --
--                                                                            --
-- You should have received a copy of the GNU General Public License          --
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.      --
--------------------------------------------------------------------------------
with Nuclear_Physics; use Nuclear_Physics;
with Ada.Real_Time;   use Ada.Real_Time;

-- This package contains utility functions to let the simulation running. The
-- Plant protected resource allows to simulate the behavior of the system.
-- author: Alberto Franco
package Plant_Simulator is

   -- Start up the simulation
   procedure Trigger_Simulation;

   -- Protected resource that simulate the plan
   protected Plant is

      -- Returns the current RC configuration
      function Get_RC_Configuration return RC_Configuration;
      -- Return current TC configuration
      function Get_TC_Configuration return TC_Configuration;

      --------------------------------------------------------------------------
      -- Utility functions for reading plant status
      --------------------------------------------------------------------------
      function Get_RC_Pressure return Float;
      function Get_Rods_Height return Float;
      function RC_Pump_Flow    return Float;
      function TC_Pump_Flow return Float;
      function Cooling_System_Temp return Float;

      --------------------------------------------------------------------------
      -- Utility procedure to actuate plant changes
      --------------------------------------------------------------------------
      procedure Raise_Control_Rods(Rods_Height: in Float);
      procedure Set_RC_Pressure(New_Pressure: in Float);
      procedure Set_RC_Pump_Flow(New_Flow: in Float);
      procedure Set_TC_Pump_Flow(New_Flow: in Float);
      procedure Set_Cooling_Temp(New_Temperature: in Float);

   private
      -- RC data
      RC_Data: RC_Configuration := (Rods_Height       => 500.0,
                                    RC_Water_Pressure => 10.0);
      RC_Pump_Flow_Ratio: Float := 100.0;
      -- TC data
      TC_Data: TC_Configuration := (RC_Conf => (Rods_Height       => 500.0,
                                                RC_Water_Pressure => 30.0),
                                    TC_Water_Pressure => 10.0);
      TC_Pump_Flow_Ratio:Float := 100.0;
      -- Cooling system data
      Cooling_System_Down_Temperature: Float := 50.0;
   end Plant;

private

   -- Simulation event type discriminate what to do when the event is triggered
   -- each one of the enumeration allows to modify one of the plant subsystems
   type Simulation_Event_Type is
     (RC_PRESSURE, RC_PUMP, TC_PUMP, COOLING_SYSTEM, RODS_HEIGHT);

   -- An event is the entity that is triggered at the given time. The container
   -- that wraps the events up is orderer and events fires after the given offset
   type Simulation_Event is
      record
         Release_Offset : Time_Span;
         Event_Type     : Simulation_Event_Type;
         Params         : Float;
      end record;

   type Index is range 1 .. 100;

   -- Simulation event queue is an array of events
   type Simulation_Event_Queue is array (Index range <>) of Simulation_Event;

   -- Task that simulate the plant. At precise time interval the task is
   -- triggered and modifies plant current configuration.
   task Plant_Simulation is
      -- Trigger for simulation start
      entry Start_Simulation(Events:Simulation_Event_Queue);
   end Plant_Simulation;

end Plant_Simulator;

