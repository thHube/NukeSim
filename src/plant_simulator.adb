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

with Ada.Text_IO; use Ada.Text_IO;

-- Implementation of the plant simulation. Here is defined the protected
-- resource that manages the plant and the private task that allow the events
-- to be fired.
-- author: Alberto Franco
package body Plant_Simulator is

   procedure Trigger_Simulation is
      Events: constant Simulation_Event_Queue :=
        ((Seconds(1), RODS_HEIGHT, 1100.0),
         (Seconds(1), RC_PRESSURE, 5.0),
         (Seconds(2), RODS_HEIGHT, 200.0),
         (Seconds(4), RC_PUMP, 30.0));
   begin
      Plant_Simulation.Start_Simulation(Events);
   end Trigger_Simulation;

   protected body Plant is
      -- Returns the current RC configuration
      function Get_RC_Configuration return RC_Configuration is
      begin
         return RC_Data;
      end Get_RC_Configuration;

      -- Return current TC configuration
      function Get_TC_Configuration return TC_Configuration is
      begin
         return TC_Data;
      end Get_TC_Configuration;

      --------------------------------------------------------------------------
      -- Utility functions for reading plant status
      --------------------------------------------------------------------------
      function Get_RC_Pressure return Float is
      begin
         return RC_Data.RC_Water_Pressure;
      end Get_RC_Pressure;

      function Get_Rods_Height return Float is
      begin
         return RC_Data.Rods_Height;
      end Get_Rods_Height;

      function RC_Pump_Flow    return Float is
      begin
         return RC_Pump_Flow_Ratio;
      end RC_Pump_Flow;

      function TC_Pump_Flow return Float is
      begin
         return TC_Pump_Flow_Ratio;
      end TC_Pump_Flow;

      function Cooling_System_Temp return Float is
      begin
         return Cooling_System_Down_Temperature;
      end Cooling_System_Temp;

      --------------------------------------------------------------------------
      -- Utility procedure to actuate plant changes
      --------------------------------------------------------------------------
      procedure Raise_Control_Rods(Rods_Height: in Float) is
      begin
         RC_Data.Rods_Height := RC_Data.Rods_Height + Rods_Height;
         TC_Data.RC_Conf := RC_Data;
      end Raise_Control_Rods;

      procedure Set_RC_Pressure(New_Pressure: in Float) is
      begin
         RC_Data.RC_Water_Pressure := New_Pressure;
         TC_Data.RC_Conf := RC_Data;
      end Set_RC_Pressure;

      procedure Set_RC_Pump_Flow(New_Flow: in Float) is
      begin
         RC_Pump_Flow_Ratio := New_Flow;
      end Set_RC_Pump_Flow;

      procedure Set_TC_Pump_Flow(New_Flow: in Float) is
      begin
         TC_Pump_Flow_Ratio := New_Flow;
      end Set_TC_Pump_Flow;

      procedure Set_Cooling_Temp(New_Temperature: in Float) is
      begin
         Cooling_System_Down_Temperature := New_Temperature;
      end Set_Cooling_Temp;
   end Plant;

   -- Simulation task implementation. It waits to be notified to start, otherwise
   -- it waits for an event queue to be submitted.
   task body Plant_Simulation is
   begin
      accept Start_Simulation (Events : Simulation_Event_Queue) do
         for I in Events'Range loop
            delay until Clock + Events(I).Release_Offset;
            Put_Line("[SIM EVENT] <" & Events(I).Event_Type'Img & ">: " & Events(I).Params'Img);
            case Events(I).Event_Type is
               when RC_PRESSURE =>
                  Plant.Set_RC_Pressure(New_Pressure => Events(I).Params);
               when RC_PUMP =>
                  Plant.Set_RC_Pump_Flow(New_Flow => Events(I).Params);
               when TC_PUMP =>
                  Plant.Set_TC_Pump_Flow(New_Flow => Events(I).Params);
               when COOLING_SYSTEM =>
                  Plant.Set_Cooling_Temp(New_Temperature => Events(I).Params);
               when RODS_HEIGHT =>
                  Plant.Raise_Control_Rods(Events(I).Params - Plant.Get_Rods_Height);
            end case;
         end loop;
      end Start_Simulation;
   end Plant_Simulation;

end Plant_Simulator;