<#

The MIT License (MIT)

Copyright (c) 2016 Michał Borejszo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>

param (
    [Parameter()]
    [int]$speed = 3,
    [switch]$nosound
)

<# get script dir #>
$dir = Split-Path $MyInvocation.MyCommand.Path
$dir_gfx = Join-Path -ChildPath "gfx" -Path $dir

Write-Host $dir_gfx

#Load the Windows Forms library.
[string]$WindowsFormsLibrary =
"System.Windows.Forms,Version=2.0.0.0,Culture=neutral,PublicKeyToken=b77a5c561934e089"
[System.Reflection.Assembly]::Load($WindowsFormsLibrary)

#Load the Drawing library.
[string]$DrawingLibrary =
"System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
[System.Reflection.Assembly]::Load($DrawingLibrary)

# Core of this crazyness
$Refs = @("System.Windows.Forms", "System.Drawing")
Add-Type -ReferencedAssemblies $Refs @'
using System;
using System.Collections;
using System.Drawing;
using System.Windows.Forms;

    public delegate void GenericDelegate();

    public partial class SnakeForm : Form
    {
        public bool KeyAvailable { get { return (_KeyFIFO.Count > 0); } }
        public Keys KeyPressed { get {
                return (Keys)_KeyFIFO.Dequeue();
            } }

        public Queue DirectionMap { get { return _DirectionMap; } }

        public Image ImHeadL { get; set; }
        public Image ImHeadR { get; set; }
        public Image ImHeadU { get; set; }
        public Image ImHeadD { get; set; }
        public Image ImBodyUD { get; set; }
        public Image ImBodyLR { get; set; }
        public Image ImTailL { get; set; }
        public Image ImTailR { get; set; }
        public Image ImTailD { get; set; }
        public Image ImTailU { get; set; }
        public Image ImApple { get; set; }
        public Image ImBlack { get; set; }
        public Image ImCornerRU { get; set; }
        public Image ImCornerLU { get; set; }
        public Image ImCornerRD { get; set; }
        public Image ImCornerLD { get; set; }

        public GenericDelegate OnTimerTick { get; set; }

        public Label GameOverLabel;

        private Timer _Timer;

        private Label ScoreLabel;
        private Label InfoLabel1;
        private Label InfoLabel2;
        private Label SpeedLabel;

        private Queue _KeyFIFO = new Queue();
        private Queue _DirectionMap = new Queue();

        public SnakeForm()
        {
            this.GameOverLabel = new Label();
            this.ScoreLabel = new System.Windows.Forms.Label();
            InfoLabel1 = new Label();
            InfoLabel2 = new Label();
            SpeedLabel = new Label();
            this.SuspendLayout();

            this.GameOverLabel.AutoSize = true;
            this.GameOverLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.GameOverLabel.ForeColor = Color.White;
            this.GameOverLabel.Location = new System.Drawing.Point(150, 300);
            this.GameOverLabel.Name = "GameOverLabel";
            this.GameOverLabel.TabIndex = 0;
            this.GameOverLabel.Text = "GAME OVER. PRESS <<ENTER>> TO CONTINUE.";
            this.GameOverLabel.Visible = false;

            this.ScoreLabel.AutoSize = true;
            this.ScoreLabel.ForeColor = Color.White;
            this.ScoreLabel.Location = new System.Drawing.Point(650, 10);
            this.ScoreLabel.Name = "ScoreLabel";
            this.ScoreLabel.TabIndex = 0;
            this.ScoreLabel.Text = "Score: {0}";
            this.ScoreLabel.Visible = true;

            this.SpeedLabel.AutoSize = true;
            this.SpeedLabel.ForeColor = Color.White;
            this.SpeedLabel.Location = new System.Drawing.Point(650, 30);
            this.SpeedLabel.Name = "SpeedLabel";
            this.SpeedLabel.TabIndex = 0;
            this.SpeedLabel.Text = "Speed: {0}";
            this.SpeedLabel.Visible = true;

            this.InfoLabel1.AutoSize = true;
            this.InfoLabel1.ForeColor = Color.White;
            this.InfoLabel1.Location = new System.Drawing.Point(650, 50);
            this.InfoLabel1.Name = "InfoLabel1";
            this.InfoLabel1.TabIndex = 0;
            this.InfoLabel1.Text = "Use arrows to steer";
            this.InfoLabel1.Visible = true;

            this.InfoLabel2.AutoSize = true;
            this.InfoLabel2.ForeColor = Color.White;
            this.InfoLabel2.Location = new System.Drawing.Point(650, 70);
            this.InfoLabel2.Name = "InfoLabel2";
            this.InfoLabel2.TabIndex = 0;
            this.InfoLabel2.Text = "ESC - Exit";
            this.InfoLabel2.Visible = true;

            this.Controls.Add(GameOverLabel);
            this.Controls.Add(ScoreLabel);
            this.Controls.Add(SpeedLabel);
            this.Controls.Add(InfoLabel1);
            this.Controls.Add(InfoLabel2);

            BackColor = Color.Black;
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.CenterScreen;

            this.ResumeLayout(false);
            this.PerformLayout();

            _Timer = new Timer();
            _Timer.Tick += _Timer_Tick;
            
            this.KeyDown += SnakeCore_KeyDown;
        }

        public void UpdateSpeed(int speed)
        {
            SpeedLabel.Text = String.Format("Speed: {0}", speed);
        }

        public void UpdateScore(int score)
        {
            ScoreLabel.Text = String.Format("Score: {0}", score);
        }

        public Keys ReadKey()
        {
            while (!KeyAvailable) ;
            return KeyPressed;
        }

        public void StartGameloop(int ms)
        {
            _Timer.Interval = ms;
            _Timer.Enabled = true;
            _Timer.Start();
        }

        public void StopGameLoop()
        {
            _Timer.Stop();
            _Timer.Enabled = false;
        }

        private void _Timer_Tick(object sender, EventArgs e)
        {
            if (OnTimerTick != null)
            { 
                OnTimerTick();
            }
        }

        private void SnakeCore_KeyDown(object sender, KeyEventArgs e)
        {
            _KeyFIFO.Enqueue(e.KeyCode);
        }
    }
'@

$board_x = 40
$board_y = 40
$sideboard_width = 10
$tile_xy = 16;

$direction_up = 0
$direction_left = 1
$direction_down = 2
$direction_right = 3

switch ($speed)
{
    1 { $speed_ = 500; break }
    2 { $speed_ = 250; break }
    3 { $speed_ = 100; break }
    4 { $speed_ = 50; break }
    5 { $speed_ = 25; break }
    default { $speed_ = 100; $speed = 3; break }
}

# returns the vector of current movement direction
function Get-Direction
{
    $dir = new-object PSObject -Property @{
        'X' = 0
        'Y' = 0
    }
    if ($global:direction -eq $direction_up)
    { 
        $dir.y = -1
        $dir.x = 0
    }
    elseif ($global:direction -eq $direction_left)
    { 
        $dir.y = 0
        $dir.x = -1
    }
    elseif ($global:direction -eq $direction_down)
    { 
        $dir.y = 1
        $dir.x = 0
    }
    elseif ($global:direction -eq $direction_right)
    { 
        $dir.y = 0
        $dir.x = 1
    }
    
    Write-Output $dir
}

function Get-Vector-Distance
{
    $dist = [System.Math]::Sqrt([System.Math]::Pow(($args[0].x - $args[1].x), 2) + [System.Math]::Pow(($args[0].y - $args[1].y), 2))
    Write-Output $dist
}

function Draw-Tile
{
param(
    $tile,
    $x,
    $y
)
    $gfx.DrawImage($tile, ($tile_xy *$x), ($tile_xy * $y))
}

function Reset-Buffer-Snake
{
    for ($i=0; $i -lt ($tile_xy * $board_x); $i += $tile_xy)
    {
        $gfx.DrawRectangle([System.Drawing.Pens]::Green, $i, 0, 16, 16)
    }
    for ($i=0; $i -lt ($tile_xy * $board_x); $i += $tile_xy)
    {
        $gfx.DrawRectangle([System.Drawing.Pens]::Green, $i, ($tile_xy * ($board_y-1)), 16, 16)
    }
    
    for ($i=0; $i -lt ($tile_xy * $board_y); $i += $tile_xy)
    {
        $gfx.DrawRectangle([System.Drawing.Pens]::Green, 0, $i, 16, 16)
    }
    for ($i=0; $i -lt ($tile_xy * $board_y); $i += $tile_xy)
    {
        $gfx.DrawRectangle([System.Drawing.Pens]::Green, ($tile_xy * ($board_x-1)), $i, 16, 16)
    }

    #Reset-Buffer $Position $board_y ($board_x + $sideboard_width) 1 -ForegroundColor 'Gray' -BackgroundColor 'Black' -BorderColor 'Green' -Title PowerSnake
}

function Draw-Board
{
    for ($x=1; $x -lt $board_x - 1; $x += 1)
    {
        for ($y=1; $y -lt $board_y - 1; $y += 1)
        {
            Draw-Tile $f.ImBlack $x $y
        }
    }
}

function Reset-Game
{
    $global:score = 0
    $global:snake = @(
        (new-object PSObject -Property @{
            'X' = ($board_x / 2)
            'Y' = ($board_y / 2)
        }),
        (new-object PSObject -Property @{
            'X' = ($board_x / 2)
            'Y' = ($board_y / 2) + 1
        }),
        (new-object PSObject -Property @{
            'X' = ($board_x / 2)
            'Y' = ($board_y / 2) + 2
        })
    )
    $global:food = new-object PSObject -Property @{
        'X' = 0
        'Y' = 0
    }
    $global:direction = $direction_up
    $global:Restarting = 1
    $f.DirectionMap.Clear()
    $global:direction = $direction_up
    $global:head_tile = $f.ImHeadU
    $global:body_tile = $f.ImBodyUD
    $global:tail_tile = $f.ImHeadU
    $f.GameOverLabel.Visible = $false
    $f.UpdateScore(0)
    Draw-Board
}

function Game-Over
{
    $global:GameOver = 1;
    $f.GameOverLabel.Visible = $true
    $f.Update()
    if(!$nosound) { [console]::Beep(500, 500) }
}

function Draw-Score
{
    $f.UpdateScore($global:score)
}

#Create a window, and set its properties.
#[System.Windows.Forms.Form]$f = New-Object System.Windows.Forms.Form
$global:f = New-Object SnakeForm
$f.Width = ($tile_xy * ($board_x + $sideboard_width))
$f.Height = ($tile_xy * $board_y)

$global:gfx = $f.CreateGraphics()

$path = Join-Path -ChildPath "guowa_wenza.png" -Path $dir_gfx
$f.ImHeadL = [System.Drawing.Image]::FromFile($path)
$f.ImHeadR = [System.Drawing.Image]::FromFile($path)
$f.ImHeadU = [System.Drawing.Image]::FromFile($path)
$f.ImHeadD = [System.Drawing.Image]::FromFile($path)
$path = Join-Path -ChildPath "ciauo_wenza.png" -Path $dir_gfx
$f.ImBodyLR = [System.Drawing.Image]::FromFile($path)
$f.ImBodyUD = [System.Drawing.Image]::FromFile($path)
$path = Join-Path -ChildPath "ogon_wenza.png" -Path $dir_gfx
$f.ImTailL = [System.Drawing.Image]::FromFile($path)
$f.ImTailR = [System.Drawing.Image]::FromFile($path)
$f.ImTailD = [System.Drawing.Image]::FromFile($path)
$f.ImTailU = [System.Drawing.Image]::FromFile($path)
$path = Join-Path -ChildPath "japko.png" -Path $dir_gfx
$f.ImApple = [System.Drawing.Image]::FromFile($path)
$path = Join-Path -ChildPath "black.png" -Path $dir_gfx
$f.ImBlack = [System.Drawing.Image]::FromFile($path)
$path = Join-Path -ChildPath "skrencony_wonsz.png" -Path $dir_gfx
$f.ImCornerRU = [System.Drawing.Image]::FromFile($path)
$f.ImCornerRD = [System.Drawing.Image]::FromFile($path)
$f.ImCornerLU = [System.Drawing.Image]::FromFile($path)
$f.ImCornerLD = [System.Drawing.Image]::FromFile($path)

Reset-Game
$global:GameOver = 0

$f.ImBodyUD.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone);
$f.ImHeadU.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone);
$f.ImHeadD.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone);
$f.ImHeadR.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone);
$f.ImTailU.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone);
$f.ImTailD.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone);
$f.ImTailR.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone);
$f.ImCornerRD.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone);
$f.ImCornerLU.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone);
$f.ImCornerLD.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone);

$f.UpdateSpeed($speed)
$f.StartGameloop($speed_)

$f.OnTimerTick = {
    $direction_changed = 0
    if ($f.KeyAvailable)
    {
        switch ($f.KeyPressed)
        {
            Return { if ($global:GameOver) { $global:GameOver = 0; Reset-Game; break } } 
            Escape { $f.Close(); break }
            Left {
                if($global:direction -ne $direction_right -and $global:direction -ne $direction_left)
                {
                    if ($global:direction -eq $direction_up)
                    {
                        $corner_tile = $f.ImCornerLD
                    }
                    if ($global:direction -eq $direction_down)
                    {
                        $corner_tile = $f.ImCornerLU
                    }
                    $global:head_tile = $f.ImHeadL
                    $global:body_tile = $f.ImBodyLR
                    $global:direction = $direction_left
                    $direction_changed = 1
                }
                break
            }
            Right { 
                if($global:direction -ne $direction_left -and $global:direction -ne $direction_right) {
                    if ($global:direction -eq $direction_up)
                    {
                        $corner_tile = $f.ImCornerRD
                    }
                    if ($global:direction -eq $direction_down)
                    {
                        $corner_tile = $f.ImCornerRU
                    }
                    $global:head_tile = $f.ImHeadR
                    $global:body_tile = $f.ImBodyLR
                    $global:direction = $direction_right
                    $direction_changed = 1
                }
                break
            }
            Up { 
                if($global:direction -ne $direction_down -and $global:direction -ne $direction_up) {
                    if ($global:direction -eq $direction_left)
                    {
                        $corner_tile = $f.ImCornerRU
                    }
                    if ($global:direction -eq $direction_right)
                    {
                        $corner_tile = $f.ImCornerLU
                    }
                    $global:head_tile = $f.ImHeadU
                    $global:body_tile = $f.ImBodyUD
                    $global:direction = $direction_up
                    $direction_changed = 1
                }
                break 
            }
            Down { 
                if($global:direction -ne $direction_up -and $global:direction -ne $direction_down) {
                    if ($global:direction -eq $direction_left)
                    {
                        $corner_tile = $f.ImCornerRD
                    }
                    if ($global:direction -eq $direction_right)
                    {
                        $corner_tile = $f.ImCornerLD
                    }
                    $global:head_tile = $f.ImHeadD
                    $global:body_tile = $f.ImBodyUD
                    $global:direction = $direction_down
                    $direction_changed = 1
                }
                break 
            }
        }
    }
    
    if ($global:GameOver)
    {
        return;
    }
    
    if ($global:Restarting)
    {
        Reset-Buffer-Snake
        
        $f.DirectionMap.Enqueue($direction_up)
        
        # draw initial snake
        foreach($s in $global:snake)
        {
            #$global:BufferPosition.x = $s.X
            #$global:BufferPosition.y = $s.y
            #Out-Buffer $global:BoxChars.FullBlock 'red' 'red' -NoScroll
            Draw-Tile $global:body_tile $s.X $s.Y
        }
        
        $global:Restarting = 0
    }
    
    # Enqueue current direction
    # We use that to draw tail in correct rotation
    $f.DirectionMap.Enqueue($global:direction)
    
    # do we have food on board?
    if ($global:food.X -eq 0 -and $global:food.Y -eq 0)
    {
        #place new food
        $global:newfood = new-object PSObject -Property @{
            'X' = 0
            'Y' = 0
        }
        while(1)
        {
            $global:newfood.X = Get-Random -Minimum 1 -Maximum ($board_x - 1)
            $global:newfood.Y = Get-Random -Minimum 1 -Maximum ($board_y - 1)
            $distance = Get-Vector-Distance $global:newfood $global:snake[0]
            if ($distance -lt 5) {continue}
            $ok = [bool]$true
            foreach($s in $snake)
            {
                if ($s.x -eq $global:newfood.x -and $s.y -eq $global:newfood.y)
                {
                    $ok = [bool]$false
                    break
                }
            }
            if ($ok)
            {
                $global:food = $global:newfood
                #$global:BufferPosition.x = $global:newfood.X
                #$global:BufferPosition.y = $global:newfood.Y
                #Out-Buffer $global:BoxChars.FullBlock 'blue' 'blue' -NoScroll
                Draw-Tile $f.ImApple $global:newfood.X $global:newfood.Y
                break
            }
        }
    }
    else
    {
        #redraw food
        #$global:BufferPosition.x = $global:food.X
        #$global:BufferPosition.y = $global:food.Y
        #Out-Buffer $global:BoxChars.FullBlock 'blue' 'blue' -NoScroll
        #Draw-Tile $f.ImHead $global:newfood.X $global:newfood.Y
    }
    
    # get current movement vector
    $movement = Get-Direction 

    #find new head
    $newhead = new-object PSObject -Property @{
        'X' = $global:snake[0].X + $movement.x
        'Y' = $global:snake[0].Y + $movement.y
    }
    $newsnake = @($newhead)
    
    #check for collisions with board borders
    if ($newhead.x -eq 0 -or $newhead.y -eq 0 -or $newhead.x -eq ($board_x - 1) -or $newhead.y -eq ($board_y - 1))
    {
        Game-Over
        return
    }

    $col = [bool]$false
    #check for collisions with snake
    foreach ($s in $snake)
    {
        if ($s.x -eq $newhead.x -and $s.y -eq $newhead.y)
        {
            $col = [bool]$true
        }
    }
    if ($col)
    {
        Game-Over
        return
    }

    $gotfood = [bool]$false
    #check for food
    if ($newhead.x -eq $global:food.x -and $newhead.y -eq $global:food.y)
    {
        $gotfood = [bool]$true
    }

    if (!$gotfood)
    {
        #erase last snake "bit"
        #$global:BufferPosition.x = $global:snake[-1].X
        #$global:BufferPosition.y = $global:snake[-1].Y
        #Out-Buffer $global:BoxChars.FullBlock 'black' 'black' -NoScroll
        Draw-Tile $f.ImBlack $global:snake[-1].X $global:snake[-1].Y

        #remove last element from array
        $global:snake = $global:snake[0..($global:snake.Length - 2)]
        
        #Draw tail
        $d = $f.DirectionMap.Dequeue()
        switch ($d)
        {
            $direction_left { $global:tail_tile = $f.ImTailL; break }
            $direction_right { $global:tail_tile = $f.ImTailR; break }
            $direction_up { $global:tail_tile = $f.ImTailU; break }
            $direction_down { $global:tail_tile = $f.ImTailD; break }
        }
        Draw-Tile $global:tail_tile $global:snake[-1].X $global:snake[-1].Y
    }
    else
    { # food eaten
        #increment score
        $global:score++
        Draw-Score

        # reset food position, so new one is generated on next pass
        $global:food.x = 0
        $global:food.y = 0
    }
    
    # move the snake array
    foreach($s in $global:snake)
    {
        $newsnake += $s
    }
    $global:snake = $newsnake

    # draw snake on late "head"
    #$global:BufferPosition.x = $global:snake[1].X
    #$global:BufferPosition.y = $global:snake[1].y
    #Out-Buffer $global:BoxChars.FullBlock 'red' 'red' -NoScroll
    if ($direction_changed)
    {
        Draw-Tile $corner_tile $global:snake[1].X $global:snake[1].Y
    }
    else {
        Draw-Tile $global:body_tile $global:snake[1].X $global:snake[1].Y
    }

    # draw new "head"
    #$global:BufferPosition.x = ($global:snake[0].X)
    #$global:BufferPosition.y = ($global:snake[0].Y)
    #Out-Buffer $global:BoxChars.FullBlock 'green' 'green' -NoScroll
    Draw-Tile $global:head_tile $global:snake[0].X $global:snake[0].Y
}


#Display the form.
$f.ShowDialog()
