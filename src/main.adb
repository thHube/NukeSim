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


with Control_Rods;      use Control_Rods;
with RC_Status;         use RC_Status;
with TC_Status;         use TC_Status;
with Output_Power;      use Output_Power;
with Plant_Simulator;   use Plant_Simulator;
with Notification;      use Notification;
with Coordinator;       use Coordinator;

procedure Main is

begin
   Put_Line("NukeSim  Copyright (C) 2012  Alberto Franco");
   Put_Line("This program comes with ABSOLUTELY NO WARRANTY; for details see LICENSE.txt .");
   Put_Line("This is free software, and you are welcome to redistribute it");
   Put_Line("under conditions established by the license.");
   Trigger_Simulation;
end Main;
