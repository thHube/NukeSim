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
with Coordinator; use Coordinator;

with Input_Sources.File; use Input_Sources.File;
with Sax.Readers;        use Sax.Readers;
with DOM.Readers;        use DOM.Readers;
with DOM.Core;           use DOM.Core;
with DOM.Core.Documents; use DOM.Core.Documents;
with DOM.Core.Nodes;     use DOM.Core.Nodes;
with DOM.Core.Attrs;     use DOM.Core.Attrs;

-- Implementation of the plant simulation. Here is defined the protected
-- resource that manages the plant and the private task that allow the events
-- to be fired.
-- author: Alberto Franco
package body Plant_Simulator is

   -- Parse a configuration file and return the event queue created
   function Parse_Config_File(Filename: in String) return Simulation_Event_Queue is
      -- XML-parsing-related data
      Input : File_Input;
      Reader: Tree_Reader;
      Doc    : Document;
      List   : Node_List;
      N      : Node;
      -- Support data
      Events : Simulation_Event_Queue := (others => (Milliseconds(1000), RC_PRESSURE, 1.0));
      Index  : Sim_Index := 0;
      Int_Idx: Integer := 0;
      -- Attributes for parsing
      Sim_Delay  : Attr;
      Sim_Type   : Attr;
      Sim_Params : Attr;
   begin
      Set_Public_Id(Input, "Configuration File");
      Open(Filename, Input);

      Set_Feature (Reader, Validation_Feature, False);
      Set_Feature (Reader, Namespace_Feature, False);

      Parse (Reader, Input);
      Close (Input);

      Doc := Get_Tree (Reader);
      List := Get_Elements_By_Tag_Name (Doc, "event");

      -- Initialize the event queue
      while Int_Idx < SIM_QUEUE_SIZE and Int_Idx < Length(List) loop
         N := Item (List, Int_Idx);
         Sim_Delay  := Get_Named_Item (Attributes (N), "delay");
         Sim_Type   := Get_Named_Item (Attributes (N), "type");
         Sim_Params := Get_Named_Item (Attributes (N), "params");

         Events(Index) := (Milliseconds(Integer'Value(Value(Sim_Delay))),
                           Simulation_Event_Type'Value(Value(Sim_Type)),
                           Float'Value(Value(Sim_Params)));

         -- Put_Line ("Read event " & Events(Index).Event_Type'Img);
         Index := Index + 1;
         Int_Idx := Int_Idx + 1;
      end loop;

      Put_Line("[*] Configuration file read, starting simulation...");

      Free (List);
      Free (Reader);

      Read_Events := Int_Idx;
      return Events;
   end Parse_Config_File;

   -- Starts the simulation
   procedure Trigger_Simulation(Config_Filename:in String) is
      Events: constant Simulation_Event_Queue := Parse_Config_File(Config_Filename);
   begin

      Plant_Simulation.Start_Simulation(Events);
      Start_Deamon.Awake_System(Seconds(2));
   end Trigger_Simulation;

   -- Shutdown plant simulation task
   procedure Kill_Simulation is
   begin
      abort Plant_Simulation;
   end Kill_Simulation;

   -- Protected resource that manages current plant status
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
      Start_Deamon.Wait_For_System_Start;
      accept Start_Simulation (Events : Simulation_Event_Queue) do
         for I in Events'Range loop
            -- Check for events
            if Integer(I) = Read_Events then exit; end if;

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
