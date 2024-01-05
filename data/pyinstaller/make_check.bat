@echo off
@rem Script to make sure the executables run after make_dist.bat.

dist\plaso\image_export.exe --troubles
dist\plaso\log2timeline.exe --troubles
dist\plaso\pinfo --troubles
dist\plaso\pinfo.exe -v test_data\pinfo_test.plaso
dist\plaso\psort.exe --troubles
dist\plaso\psteal.exe --troubles