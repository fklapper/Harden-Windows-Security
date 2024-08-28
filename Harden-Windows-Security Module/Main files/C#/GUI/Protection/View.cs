﻿using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Markup;
using System.Xml;
using System.Windows.Media.Imaging;
using System.Linq;
using System.Windows.Forms;
using System.Collections.Concurrent;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Effects;
using System.Windows.Threading;
using System.Runtime.CompilerServices;
using System.Diagnostics;
using System.ComponentModel;
using System.Threading;
using System.Windows.Automation;
using System.Windows.Controls.Ribbon;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Forms.Integration;
using System.Windows.Ink;
using System.Windows.Media.Animation;
using System.Windows.Media.Media3D;
using System.Windows.Media.TextFormatting;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Windows.Shell;
using System.Threading.Tasks;
using System.Text;
using System.Reflection.PortableExecutable;

#nullable disable

namespace HardenWindowsSecurity
{
    public partial class GUIMain
    {

        // NavigationVM class
        public partial class NavigationVM : ViewModelBase
        {

            // Method to handle the Protect view, including loading
            private void Protect(object obj)
            {
                // Check if the view is already cached
                if (_viewCache.TryGetValue("ProtectView", out var cachedView))
                {
                    CurrentView = cachedView;
                    return;
                }

                // Defining the path to the XAML XML file
                if (HardenWindowsSecurity.GlobalVars.path == null)
                {
                    throw new System.ArgumentNullException("GlobalVars.path cannot be null.");
                }

                // Construct the file path for the Protect view XAML
                string xamlPath = System.IO.Path.Combine(HardenWindowsSecurity.GlobalVars.path, "Resources", "XAML", "Protect.xaml");

                // Read the XAML content from the file
                string xamlContent = File.ReadAllText(xamlPath);

                // Parse the XAML content to create a UserControl
                GUIProtectWinSecurity.View = (System.Windows.Controls.UserControl)XamlReader.Parse(xamlContent);

                // Set the DataContext for Protect view
                GUIProtectWinSecurity.View.DataContext = new ProtectVM();

                GUIProtectWinSecurity.parentGrid = (System.Windows.Controls.Grid)GUIProtectWinSecurity.View.FindName("ParentGrid");
                GUIProtectWinSecurity.mainTabControlToggle = (System.Windows.Controls.Primitives.ToggleButton)GUIProtectWinSecurity.parentGrid.FindName("MainTabControlToggle");
                GUIProtectWinSecurity.mainContentControl = (System.Windows.Controls.ContentControl)GUIProtectWinSecurity.mainTabControlToggle.FindName("MainContentControl");

                // Finding the progress bar
                GUIProtectWinSecurity.mainProgressBar = (System.Windows.Controls.ProgressBar)GUIProtectWinSecurity.parentGrid.FindName("MainProgressBar");

                // Set Main progress bar visibility initially to Collapsed
                GUIProtectWinSecurity.mainProgressBar.Visibility = Visibility.Collapsed;

                // Due to using ToggleButton as Tab Control element, this is now considered the parent of all inner elements
                GUIProtectWinSecurity.mainContentControlStyle = (System.Windows.Style)GUIProtectWinSecurity.mainContentControl.FindName("MainContentControlStyle");

                GUIProtectWinSecurity.outputTextBlock = (System.Windows.Controls.TextBox)GUIProtectWinSecurity.parentGrid.FindName("OutputTextBlock");
                GUIProtectWinSecurity.scrollerForOutputTextBlock = (System.Windows.Controls.ScrollViewer)GUIProtectWinSecurity.parentGrid.FindName("ScrollerForOutputTextBlock");

                // Assigning image source paths to the buttons
                // Need to cast the Style to the INameScope before using FindName method on it
                // more info: https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/interfaces/explicit-interface-implementation
                // in PowerShell this would simply work:
                //
                // [System.Windows.Style]$MainContentControlStyle = $MainContentControl.FindName('MainContentControlStyle')
                // $MainContentControlStyle.FindName('PathIcon1').Source
                ((System.Windows.Controls.Image)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("PathIcon1")).Source = new System.Windows.Media.Imaging.BitmapImage(new Uri(System.IO.Path.Combine(HardenWindowsSecurity.GlobalVars.path, "Resources", "Media", "path.png")));
                ((System.Windows.Controls.Image)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("PathIcon2")).Source = new System.Windows.Media.Imaging.BitmapImage(new Uri(System.IO.Path.Combine(HardenWindowsSecurity.GlobalVars.path, "Resources", "Media", "path.png")));
                ((System.Windows.Controls.Image)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("PathIcon3")).Source = new System.Windows.Media.Imaging.BitmapImage(new Uri(System.IO.Path.Combine(HardenWindowsSecurity.GlobalVars.path, "Resources", "Media", "path.png")));
                ((System.Windows.Controls.Image)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("LogButtonIcon")).Source = new System.Windows.Media.Imaging.BitmapImage(new Uri(System.IO.Path.Combine(HardenWindowsSecurity.GlobalVars.path, "Resources", "Media", "log.png")));


                // Access the grid containing the Execute Button
                GUIProtectWinSecurity.ExecuteButtonGrid = GUIProtectWinSecurity.parentGrid.FindName("ExecuteButtonGrid") as System.Windows.Controls.Grid;

                // Access the Execute Button
                GUIProtectWinSecurity.ExecuteButton = (System.Windows.Controls.Primitives.ToggleButton)GUIProtectWinSecurity.ExecuteButtonGrid!.FindName("Execute");

                // Register the Execute button to be enabled/disabled based on global activity
                HardenWindowsSecurity.ActivityTracker.RegisterUIElement(GUIProtectWinSecurity.ExecuteButton);

                // Apply the template to make sure it's available
                GUIProtectWinSecurity.ExecuteButton.ApplyTemplate();

                // Access the image within the Execute Button's template
                GUIProtectWinSecurity.ExecuteButtonImage = GUIProtectWinSecurity.ExecuteButton.Template.FindName("ExecuteIconImage", GUIProtectWinSecurity.ExecuteButton) as System.Windows.Controls.Image;

                // Update the image source for the execute button
                GUIProtectWinSecurity.ExecuteButtonImage!.Source =
                    new System.Windows.Media.Imaging.BitmapImage(
                        new Uri(System.IO.Path.Combine(HardenWindowsSecurity.GlobalVars.path!, "Resources", "Media", "ExecuteButton.png"))
                    );

                GUIProtectWinSecurity.categories = (System.Windows.Controls.ListView)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("Categories");
                GUIProtectWinSecurity.subCategories = (System.Windows.Controls.ListView)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("SubCategories");
                GUIProtectWinSecurity.selectAllCategories = (System.Windows.Controls.CheckBox)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("SelectAllCategories");
                GUIProtectWinSecurity.selectAllSubCategories = (System.Windows.Controls.CheckBox)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("SelectAllSubCategories");

                // New initialization for Log related elements
                GUIProtectWinSecurity.txtFilePath = (System.Windows.Controls.TextBox)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("txtFilePath");
                GUIProtectWinSecurity.logPath = (System.Windows.Controls.Button)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("LogPath");
                GUIProtectWinSecurity.log = (System.Windows.Controls.Primitives.ToggleButton)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("Log");
                GUIProtectWinSecurity.loggingViewBox = (System.Windows.Controls.Viewbox)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("LoggingViewBox");


                // initializations for Offline-Mode related elements
                GUIProtectWinSecurity.grid2 = (System.Windows.Controls.Grid)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("Grid2");
                GUIProtectWinSecurity.enableOfflineMode = (System.Windows.Controls.Primitives.ToggleButton)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("EnableOfflineMode");
                GUIProtectWinSecurity.microsoftSecurityBaselineZipButton = (System.Windows.Controls.Button)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("MicrosoftSecurityBaselineZipButton");
                GUIProtectWinSecurity.microsoftSecurityBaselineZipTextBox = (System.Windows.Controls.TextBox)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("MicrosoftSecurityBaselineZipTextBox");
                GUIProtectWinSecurity.microsoft365AppsSecurityBaselineZipButton = (System.Windows.Controls.Button)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("Microsoft365AppsSecurityBaselineZipButton");
                GUIProtectWinSecurity.microsoft365AppsSecurityBaselineZipTextBox = (System.Windows.Controls.TextBox)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("Microsoft365AppsSecurityBaselineZipTextBox");
                GUIProtectWinSecurity.lgpoZipButton = (System.Windows.Controls.Button)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("LGPOZipButton");
                GUIProtectWinSecurity.lgpoZipTextBox = (System.Windows.Controls.TextBox)((System.Windows.Markup.INameScope)GUIProtectWinSecurity.mainContentControlStyle).FindName("LGPOZipTextBox");

                // Initially set the text area for the selected LogPath to disabled
                GUIProtectWinSecurity.txtFilePath.IsEnabled = false;

                // Initialize the LogPath button element as disabled
                GUIProtectWinSecurity.logPath.IsEnabled = false;

                // Defining event handler
                // When the Log checkbox is checked, enable the LogPath button and log path text area
                GUIProtectWinSecurity.log.Checked += (sender, e) =>
                {
                    GUIProtectWinSecurity.txtFilePath.IsEnabled = true;
                    GUIProtectWinSecurity.logPath.IsEnabled = true;
                };

                // Defining event handler
                // When the Log checkbox is unchecked, disable the LogPath button and set the LogPath text area to disabled
                GUIProtectWinSecurity.log.Unchecked += (sender, e) =>
                {
                    GUIProtectWinSecurity.logPath.IsEnabled = false;

                    // Only disable the Log text file path element if it's not empty
                    if (string.IsNullOrWhiteSpace(GUIProtectWinSecurity.txtFilePath.Text))
                    {
                        GUIProtectWinSecurity.txtFilePath.IsEnabled = false;
                    }
                };

                // Event handler for the Log Path button click to open a file path picker dialog
                GUIProtectWinSecurity.logPath.Click += (sender, e) =>
                {
                    using (SaveFileDialog dialog = new SaveFileDialog())
                    {
                        // Defining the initial directory where the file picker GUI will be opened for the user
                        dialog.InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                        dialog.Filter = "Text files (*.txt)|*.txt";
                        dialog.Title = "Choose where to save the log file";

                        if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                        {
                            GUIProtectWinSecurity.txtFilePath.Text = dialog.FileName;
                            HardenWindowsSecurity.Logger.LogMessage($"Logs will be saved in: {GUIProtectWinSecurity.txtFilePath.Text}");
                        }
                    }
                };

                // Initially disable the Offline Mode configuration inputs until the Offline Mode checkbox is checked
                GUIProtectWinSecurity.DisableOfflineModeConfigInputs();

                // Implement the event handlers for the UI elements
                GUIProtectWinSecurity.AddEventHandlers();

                // Update the sub-categories based on the initial unchecked state of the categories
                GUIProtectWinSecurity.UpdateSubCategories();


                if (!HardenWindowsSecurity.GlobalVars.Offline)
                {
                    // Disable the Offline mode toggle button if -Offline parameter was not used with the function
                    GUIProtectWinSecurity.enableOfflineMode.IsEnabled = false;

                    // Display a message showing how to activate the offline mode

                    // Add a new row definition for the text message
                    System.Windows.Controls.RowDefinition offlineModeUnavailableRow = new System.Windows.Controls.RowDefinition
                    {
                        Height = new System.Windows.GridLength(50)
                    };
                    GUIProtectWinSecurity.grid2.RowDefinitions.Add(offlineModeUnavailableRow);

                    // Create a new text box
                    System.Windows.Controls.TextBox offlineModeUnavailableNoticeBox = new System.Windows.Controls.TextBox
                    {
                        HorizontalAlignment = System.Windows.HorizontalAlignment.Stretch,
                        VerticalAlignment = System.Windows.VerticalAlignment.Stretch,
                        TextWrapping = System.Windows.TextWrapping.Wrap,
                        Text = "To enable offline mode, use: Protect-WindowsSecurity -GUI -Offline",
                        TextAlignment = System.Windows.TextAlignment.Center,
                        Background = System.Windows.Media.Brushes.Transparent,
                        FontSize = 20,
                        BorderThickness = new System.Windows.Thickness(0),
                        Margin = new System.Windows.Thickness(10, 20, 10, 0),
                        ToolTip = "To enable offline mode, use: Protect-WindowsSecurity -GUI -Offline"
                    };
                    offlineModeUnavailableNoticeBox.SetValue(System.Windows.Controls.Grid.ColumnSpanProperty, 2);
                    offlineModeUnavailableNoticeBox.SetValue(System.Windows.Controls.Grid.RowProperty, 4);

                    // Create a gradient brush for the text color
                    System.Windows.Media.LinearGradientBrush gradientBrush = new System.Windows.Media.LinearGradientBrush();
                    gradientBrush.GradientStops.Add(new System.Windows.Media.GradientStop(System.Windows.Media.Colors.Purple, 0));
                    gradientBrush.GradientStops.Add(new System.Windows.Media.GradientStop(System.Windows.Media.Colors.Blue, 1));
                    offlineModeUnavailableNoticeBox.Foreground = gradientBrush;

                    // Add the text box to the grid
                    GUIProtectWinSecurity.grid2.Children.Add(offlineModeUnavailableNoticeBox);
                };

                // Cache the view before setting it as the CurrentView
                _viewCache["ProtectView"] = GUIProtectWinSecurity.View;

                // Set the CurrentView to the Protect view
                CurrentView = GUIProtectWinSecurity.View;
            }

        }
    }
}