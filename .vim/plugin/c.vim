"###############################################################################################
"
"       Filename:  c.vim
"
"    Description:  C/C++-IDE. Write programs by inserting complete statements,
"                  comments, idioms, code snippets, templates and comments.
"                  Compile, link and run one-file-programs without a makefile.
"                  See also help file csupport.txt .
"
"   GVIM Version:  7.0+
"
"  Configuration:  There are some personal details which should be configured
"                   (see the files README.csupport and csupport.txt).
"
"         Author:  Dr.-Ing. Fritz Mehner, FH Südwestfalen, 58644 Iserlohn, Germany
"          Email:  mehner@fh-swf.de
"
"        Version:  see variable  g:C_Version  below
"        Created:  04.11.2000
"        License:  Copyright (c) 2000-2009, Fritz Mehner
"                  This program is free software; you can redistribute it and/or
"                  modify it under the terms of the GNU General Public License as
"                  published by the Free Software Foundation, version 2 of the
"                  License.
"                  This program is distributed in the hope that it will be
"                  useful, but WITHOUT ANY WARRANTY; without even the implied
"                  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
"                  PURPOSE.
"                  See the GNU General Public License version 2 for more details.
"       Revision:  $Id: c.vim,v 1.81 2009/04/30 15:00:22 mehner Exp $
"
"------------------------------------------------------------------------------
"
if v:version < 700
  echohl WarningMsg | echo 'The plugin c-support.vim needs Vim version >= 7 .'| echohl None
  finish
endif
"
" Prevent duplicate loading:
"
if exists("g:C_Version") || &cp
 finish
endif
let g:C_Version= "5.7"  							" version number of this script; do not change
"
"###############################################################################################
"
"  Global variables (with default values) which can be overridden.
"
" Platform specific items:  {{{1
" - root directory
" - characters that must be escaped for filenames
"
let	s:MSWIN =		has("win16") || has("win32") || has("win64") || has("win95")
"
if	s:MSWIN
	"
  let s:escfilename      = ''
  let s:plugin_dir       = $VIM.'\vimfiles\'
  let s:C_CodeSnippets   = s:plugin_dir.'c-support/codesnippets/'
  let s:C_IndentErrorLog = $HOME.'.indent.errorlog'
	let s:installation	   = 'system'
	"
	let s:C_Display        = ''
	"
else
	"
  let s:escfilename 	= ' \%#[]'
	let s:installation	= 'local'
	"
	" user / system wide installation (Linux/Unix)
	"
	if match( expand("<sfile>"), $VIM ) >= 0
		" system wide installation
		let s:plugin_dir  = $VIM.'/vimfiles/'
		let s:installation	= 'system'
	else
		" user installation assumed
		let s:plugin_dir  = $HOME.'/.vim/'
	endif
	"
	let s:C_CodeSnippets   = $HOME.'/.vim/c-support/codesnippets/'
	let s:C_IndentErrorLog = $HOME.'/.indent.errorlog'
	"
"	let s:C_Display	= system("echo -n $DISPLAY")
	"
endif
"  Use of dictionaries  {{{1
"  Key word completion is enabled by the filetype plugin 'c.vim'
"  g:C_Dictionary_File  must be global
"
if !exists("g:C_Dictionary_File")
  let g:C_Dictionary_File = s:plugin_dir.'c-support/wordlists/c-c++-keywords.list,'.
        \                   s:plugin_dir.'c-support/wordlists/k+r.list,'.
        \                   s:plugin_dir.'c-support/wordlists/stl_index.list'
endif
"
"  Modul global variables (with default values) which can be overridden. {{{1
"
if	s:MSWIN
	let s:C_CCompiler           = 'gcc.exe'  " the C   compiler
	let s:C_CplusCompiler       = 'g++.exe'  " the C++ compiler
	let s:C_ExeExtension        = '.exe'     " file extension for executables (leading point required)
	let s:C_ObjExtension        = '.obj'     " file extension for objects (leading point required)
	let s:C_Man                 = 'man.exe'  " the manual program
else
	let s:C_CCompiler           = 'gcc'      " the C   compiler
	let s:C_CplusCompiler       = 'g++'      " the C++ compiler
	let s:C_ExeExtension        = ''         " file extension for executables (leading point required)
	let s:C_ObjExtension        = '.o'       " file extension for objects (leading point required)
	let s:C_Man                 = 'man'      " the manual program
endif
"
let s:C_CExtension     				= 'c'                    " C file extension; everything else is C++
let s:C_CFlags         				= '-Wall -g -O0 -c'      " compiler flags: compile, don't optimize
let s:C_CodeCheckExeName      = 'check'
let s:C_CodeCheckOptions      = '-K13'
let s:C_LFlags         				= '-Wall -g -O0'         " compiler flags: link   , don't optimize
let s:C_Libs           				= '-lm'                  " libraries to use
let s:C_LineEndCommColDefault = 49
let s:C_LoadMenus      				= 'yes'
let s:C_MenuHeader     				= 'yes'
let s:C_OutputGvim            = 'vim'
let s:C_Printheader           = "%<%f%h%m%<  %=%{strftime('%x %X')}     Page %N"
let s:C_Root  	       				= '&C\/C\+\+.'           " the name of the root menu of this plugin
let s:C_TypeOfH               = 'cpp'
let s:C_Wrapper               = s:plugin_dir.'c-support/scripts/wrapper.sh'
let s:C_XtermDefaults         = '-fa courier -fs 12 -geometry 80x24'
"
let s:C_GlobalTemplateFile    = s:plugin_dir.'c-support/templates/Templates'
let s:C_GlobalTemplateDir     = fnamemodify( s:C_GlobalTemplateFile, ":p:h" ).'/'
let s:C_LocalTemplateFile     = $HOME.'/.vim/c-support/templates/Templates'
let s:C_LocalTemplateDir      = fnamemodify( s:C_LocalTemplateFile, ":p:h" ).'/'
let s:C_TemplateOverwrittenMsg= 'yes'
let s:C_Ctrl_j								 = 'on'
"
let s:C_FormatDate						= '%x'
let s:C_FormatTime						= '%X'
let s:C_FormatYear						= '%Y'
let s:C_SourceCodeExtensions  = 'c cc cp cxx cpp CPP c++ C i ii'
"
"------------------------------------------------------------------------------
"
"  Look for global variables (if any), to override the defaults.
"
function! C_CheckGlobal ( name )
  if exists('g:'.a:name)
    exe 'let s:'.a:name.'  = g:'.a:name
  endif
endfunction    " ----------  end of function C_CheckGlobal ----------
"
call C_CheckGlobal('C_Ctrl_j                 ')
call C_CheckGlobal('C_CCompiler              ')
call C_CheckGlobal('C_CExtension             ')
call C_CheckGlobal('C_CFlags                 ')
call C_CheckGlobal('C_CodeCheckExeName       ')
call C_CheckGlobal('C_CodeCheckOptions       ')
call C_CheckGlobal('C_CodeSnippets           ')
call C_CheckGlobal('C_CplusCompiler          ')
call C_CheckGlobal('C_ExeExtension           ')
call C_CheckGlobal('C_FormatDate             ')
call C_CheckGlobal('C_FormatTime             ')
call C_CheckGlobal('C_FormatYear             ')
call C_CheckGlobal('C_GlobalTemplateFile     ')
call C_CheckGlobal('C_IndentErrorLog         ')
call C_CheckGlobal('C_LFlags                 ')
call C_CheckGlobal('C_Libs                   ')
call C_CheckGlobal('C_LineEndCommColDefault  ')
call C_CheckGlobal('C_LoadMenus              ')
call C_CheckGlobal('C_LocalTemplateFile      ')
call C_CheckGlobal('C_Man                    ')
call C_CheckGlobal('C_MenuHeader             ')
call C_CheckGlobal('C_ObjExtension           ')
call C_CheckGlobal('C_OutputGvim             ')
call C_CheckGlobal('C_Printheader            ')
call C_CheckGlobal('C_Root                   ')
call C_CheckGlobal('C_SourceCodeExtensions   ')
call C_CheckGlobal('C_TemplateOverwrittenMsg ')
call C_CheckGlobal('C_TypeOfH                ')
call C_CheckGlobal('C_XtermDefaults          ')
"
"----- some variables for internal use only -----------------------------------
"
"
" set default geometry if not specified
"
if match( s:C_XtermDefaults, "-geometry\\s\\+\\d\\+x\\d\\+" ) < 0
	let s:C_XtermDefaults	= s:C_XtermDefaults." -geometry 80x24"
endif
"
" escape the printheader
"
let s:C_Printheader  = escape( s:C_Printheader, ' %' )
"
let s:C_HlMessage    = ""
"
" characters that must be escaped for filenames
"
let s:C_If0_Counter   = 0
let s:C_If0_Txt		 		= "If0Label_"
"
let s:C_SplintIsExecutable	= 0
if executable( "splint" )
	let s:C_SplintIsExecutable	= 1
endif
"
let s:C_CodeCheckIsExecutable	= 0
if executable( s:C_CodeCheckExeName )
	let s:C_CodeCheckIsExecutable	= 1
endif
"
"------------------------------------------------------------------------------
"  Control variables (not user configurable)
"------------------------------------------------------------------------------
let s:Attribute                = { 'below':'', 'above':'', 'start':'', 'append':'', 'insert':'' }
let s:C_Attribute              = {}
let s:C_ExpansionLimit         = 10
let s:C_FileVisited            = []
"
let s:C_MacroNameRegex         = '\([a-zA-Z][a-zA-Z0-9_]*\)'
let s:C_MacroLineRegex				 = '^\s*|'.s:C_MacroNameRegex.'|\s*=\s*\(.*\)'
let s:C_MacroCommentRegex			 = '^\$'
let s:C_ExpansionRegex				 = '|?'.s:C_MacroNameRegex.'\(:\a\)\?|'
let s:C_NonExpansionRegex			 = '|'.s:C_MacroNameRegex.'\(:\a\)\?|'
"
let s:C_TemplateNameDelimiter  = '-+_,\. '
let s:C_TemplateLineRegex			 = '^==\s*\([a-zA-Z][0-9a-zA-Z'.s:C_TemplateNameDelimiter
let s:C_TemplateLineRegex			.= ']\+\)\s*==\s*\([a-z]\+\s*==\)\?'
let s:C_TemplateIf						 = '^==\s*IF\s\+|STYLE|\s\+IS\s\+'.s:C_MacroNameRegex.'\s*=='
let s:C_TemplateEndif					 = '^==\s*ENDIF\s*=='
"
let s:C_ExpansionCounter       = {}
let s:C_TJT										 = '[ 0-9a-zA-Z_]*'
let s:C_TemplateJumpTarget1    = '<+'.s:C_TJT.'+>\|{+'.s:C_TJT.'+}'
let s:C_TemplateJumpTarget2    = '<-'.s:C_TJT.'->\|{-'.s:C_TJT.'-}'
let s:C_Template               = {}
let s:C_Macro                  = {'|AUTHOR|'         : 'first name surname',
											\						'|AUTHORREF|'      : '',
											\						'|EMAIL|'          : '',
											\						'|COMPANY|'        : '',
											\						'|PROJECT|'        : '',
											\						'|COPYRIGHTHOLDER|': '',
											\						'|STYLE|'          : ''
											\						}
let	s:C_MacroFlag								= {	':l' : 'lowercase'			,
											\							':u' : 'uppercase'			,
											\							':c' : 'capitalize'		,
											\							':L' : 'legalize name'	,
											\						}

let s:C_ForTypes     = [
    \ 'char '              ,
    \ 'int '               ,
    \ 'long int '          ,
    \ 'long '              ,
    \ 'short int '         ,
    \ 'short '             ,
    \ 'size_t '            ,
    \ 'unsigned char '     ,
    \ 'unsigned int '      ,
    \ 'unsigned long int ' ,
    \ 'unsigned long '     ,
    \ 'unsigned short int ', 
    \ 'unsigned short '    , 
    \ 'unsigned '          , 
    \ ]

let s:MsgInsNotAvail	= "insertion not available for a fold" 

"------------------------------------------------------------------------------

let s:C_SourceCodeExtensionsList	= split( s:C_SourceCodeExtensions, '\s\+' )

"------------------------------------------------------------------------------

"------------------------------------------------------------------------------
"  C : C_InitMenus                              {{{1
"  Initialization of C support menus
"------------------------------------------------------------------------------
"
" the menu names
"
let s:Comments     = s:C_Root.'&Comments'
let s:Statements   = s:C_Root.'&Statements'
let s:Idioms       = s:C_Root.'&Idioms'
let s:Preprocessor = s:C_Root.'&Preprocessor'
let s:Snippets     = s:C_Root.'S&nippets'
let s:Cpp          = s:C_Root.'C&++'
let s:Run          = s:C_Root.'&Run'
"
function! C_InitMenus ()
	"
	"===============================================================================================
	"----- Menu : C main menu entry -------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_Root != ""
		if s:C_MenuHeader == 'yes'
			exe "amenu  ".s:C_Root.'C\/C\+\+    <Nop>'
			exe "amenu  ".s:C_Root.'-Sep00-     <Nop>'
		endif
	endif
	"
	"===============================================================================================
	"----- Menu : C-Comments --------------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_MenuHeader == 'yes'
		exe "amenu  ".s:C_Root.'&Comments.&Comments<Tab>C\/C\+\+             <Nop>'
		exe "amenu  ".s:C_Root.'&Comments.-Sep00-                            <Nop>'
	endif
	exe "amenu <silent> ".s:Comments.'.end-of-&line\ comment           :call C_LineEndComment( )<CR>'
	exe "vmenu <silent> ".s:Comments.'.end-of-&line\ comment           <Esc>:call C_MultiLineEndComments( )<CR>'

	exe "amenu <silent> ".s:Comments.'.ad&just\ end-of-line\ com\.     :call C_AdjustLineEndComm("a")<CR>'
	exe "vmenu <silent> ".s:Comments.'.ad&just\ end-of-line\ com\.     :call C_AdjustLineEndComm("v")<CR>'

	exe "amenu <silent> ".s:Comments.'.&set\ end-of-line\ com\.\ col\. :call C_GetLineEndCommCol()<CR>'

	exe "amenu  ".s:Comments.'.-SEP10-                              :'
	exe "amenu <silent> ".s:Comments.'.code\ ->\ comment\ \/&*\ *\/   		 :call C_CodeComment("a","yes")<CR>:nohlsearch<CR>j'
	exe "vmenu <silent> ".s:Comments.'.code\ ->\ comment\ \/&*\ *\/  	<Esc>:call C_CodeComment("v","yes")<CR>:nohlsearch<CR>j'
	exe "amenu <silent> ".s:Comments.'.code\ ->\ comment\ &\/\/            :call C_CodeComment("a","no")<CR>:nohlsearch<CR>j'
	exe "vmenu <silent> ".s:Comments.'.code\ ->\ comment\ &\/\/       <Esc>:call C_CodeComment("v","no")<CR>:nohlsearch<CR>j'
	exe "amenu <silent> ".s:Comments.'.c&omment\ ->\ code                  :call C_CommentCode("a")<CR>:nohlsearch<CR>'
	exe "vmenu <silent> ".s:Comments.'.c&omment\ ->\ code                  :call C_CommentCode("v")<CR>:nohlsearch<CR>'

	exe "amenu          ".s:Comments.'.-SEP0-                        :'
	exe "amenu <silent> ".s:Comments.'.&frame\ comment               :call C_InsertTemplate("comment.frame")<CR>'
	exe "amenu <silent> ".s:Comments.'.f&unction\ description        :call C_InsertTemplate("comment.function")<CR>'
	exe "amenu          ".s:Comments.'.-SEP1-                        :'
	exe "amenu <silent> ".s:Comments.'.&method\ description          :call C_InsertTemplate("comment.method")<CR>'
	exe "amenu <silent> ".s:Comments.'.cl&ass\ description           :call C_InsertTemplate("comment.class")<CR>'
	exe "amenu          ".s:Comments.'.-SEP2-                        :'
	exe "amenu <silent> ".s:Comments.'.file\ description\ \(impl\.\) :call C_InsertTemplate("comment.file-description")<CR>'
	exe "amenu <silent> ".s:Comments.'.file\ description\ \(header\) :call C_InsertTemplate("comment.file-description-header")<CR>'
	exe "amenu          ".s:Comments.'.-SEP3-                        :'
	"
	"----- Submenu : C-Comments : file sections  -------------------------------------------------------------
	"
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.file\ sections<Tab>C\/C\+\+            <Nop>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.-Sep0-                                 <Nop>'
	"
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.&Header\ File\ Includes  :call C_InsertTemplate("comment.file-section-cpp-header-includes")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.Local\ &Macros           :call C_InsertTemplate("comment.file-section-cpp-macros")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.Local\ &Type\ Def\.      :call C_InsertTemplate("comment.file-section-cpp-typedefs")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.Local\ &Data\ Types      :call C_InsertTemplate("comment.file-section-cpp-data-types")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.Local\ &Variables        :call C_InsertTemplate("comment.file-section-cpp-local-variables")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.Local\ &Prototypes       :call C_InsertTemplate("comment.file-section-cpp-prototypes")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.&Exp\.\ Function\ Def\.  :call C_InsertTemplate("comment.file-section-cpp-function-defs-exported")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.&Local\ Function\ Def\.  :call C_InsertTemplate("comment.file-section-cpp-function-defs-local")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.-SEP6-                   :'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.Local\ &Class\ Def\.     :call C_InsertTemplate("comment.file-section-cpp-class-defs")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.E&xp\.\ Class\ Impl\.    :call C_InsertTemplate("comment.file-section-cpp-class-implementations-exported")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.L&ocal\ Class\ Impl\.    :call C_InsertTemplate("comment.file-section-cpp-class-implementations-local")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.-SEP7-                   :'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.&All\ sections,\ C       :call C_Comment_C_SectionAll("c")<CR>'
	exe "amenu  ".s:Comments.'.&C\/C\+\+-file\ sections.All\ &sections,\ C++     :call C_Comment_C_SectionAll("cpp")<CR>'
	"
	"----- Submenu : H-Comments : file sections  -------------------------------------------------------------
	"
	exe "amenu  ".s:Comments.'.&H-file\ sections.H-file\ sections<Tab>C\/C\+\+  <Nop>'
	exe "amenu  ".s:Comments.'.&H-file\ sections.-Sep0-                         <Nop>'
	"'
	exe "amenu  ".s:Comments.'.&H-file\ sections.&Header\ File\ Includes    :call C_InsertTemplate("comment.file-section-hpp-header-includes")<CR>'
	exe "amenu  ".s:Comments.'.&H-file\ sections.Exported\ &Macros          :call C_InsertTemplate("comment.file-section-hpp-macros")<CR>'
	exe "amenu  ".s:Comments.'.&H-file\ sections.Exported\ &Type\ Def\.     :call C_InsertTemplate("comment.file-section-hpp-exported-typedefs")<CR>'
	exe "amenu  ".s:Comments.'.&H-file\ sections.Exported\ &Data\ Types     :call C_InsertTemplate("comment.file-section-hpp-exported-data-types")<CR>'
	exe "amenu  ".s:Comments.'.&H-file\ sections.Exported\ &Variables       :call C_InsertTemplate("comment.file-section-hpp-exported-variables")<CR>'
	exe "amenu  ".s:Comments.'.&H-file\ sections.Exported\ &Funct\.\ Decl\. :call C_InsertTemplate("comment.file-section-hpp-exported-function-declarations")<CR>'
	exe "amenu  ".s:Comments.'.&H-file\ sections.-SEP4-                     :'
	exe "amenu  ".s:Comments.'.&H-file\ sections.E&xported\ Class\ Def\.    :call C_InsertTemplate("comment.file-section-hpp-exported-class-defs")<CR>'

	exe "amenu  ".s:Comments.'.&H-file\ sections.-SEP5-                     :'
	exe "amenu  ".s:Comments.'.&H-file\ sections.&All\ sections,\ C         :call C_Comment_H_SectionAll("c")<CR>'
	exe "amenu  ".s:Comments.'.&H-file\ sections.All\ &sections,\ C++       :call C_Comment_H_SectionAll("cpp")<CR>'
	"
	exe "amenu  ".s:Comments.'.-SEP8-                        :'
	"
	"----- Submenu : C-Comments : keyword comments  ----------------------------------------------------------
	"
	exe "amenu  ".s:Comments.'.&keyword\ comm\..keyw\.+comm\.<Tab>C\/C\+\+   <Nop>'
	exe "amenu  ".s:Comments.'.&keyword\ comm\..-Sep0-            						<Nop>'
"
	exe "amenu  ".s:Comments.'.&keyword\ comm\..\:&BUG\:               $:call C_InsertTemplate("comment.keyword-bug")<CR>'
	exe "amenu  ".s:Comments.'.&keyword\ comm\..\:&COMPILER\:          $:call C_InsertTemplate("comment.keyword-compiler")<CR>'
	exe "amenu  ".s:Comments.'.&keyword\ comm\..\:&TODO\:              $:call C_InsertTemplate("comment.keyword-todo")<CR>'
	exe "amenu  ".s:Comments.'.&keyword\ comm\..\:T&RICKY\:            $:call C_InsertTemplate("comment.keyword-tricky")<CR>'
	exe "amenu  ".s:Comments.'.&keyword\ comm\..\:&WARNING\:           $:call C_InsertTemplate("comment.keyword-warning")<CR>'
	exe "amenu  ".s:Comments.'.&keyword\ comm\..\:W&ORKAROUND\:        $:call C_InsertTemplate("comment.keyword-workaround")<CR>'
	exe "amenu  ".s:Comments.'.&keyword\ comm\..\:&new\ keyword\:      $:call C_InsertTemplate("comment.keyword-keyword")<CR>'
"
	exe "imenu  ".s:Comments.'.&keyword\ comm\..\:&BUG\:          <Esc>$:call C_InsertTemplate("comment.keyword-bug")<CR>'
	exe "imenu  ".s:Comments.'.&keyword\ comm\..\:&COMPILER\:     <Esc>$:call C_InsertTemplate("comment.keyword-compiler")<CR>'
	exe "imenu  ".s:Comments.'.&keyword\ comm\..\:&TODO\:         <Esc>$:call C_InsertTemplate("comment.keyword-todo")<CR>'
	exe "imenu  ".s:Comments.'.&keyword\ comm\..\:T&RICKY\:       <Esc>$:call C_InsertTemplate("comment.keyword-tricky")<CR>'
	exe "imenu  ".s:Comments.'.&keyword\ comm\..\:&WARNING\:      <Esc>$:call C_InsertTemplate("comment.keyword-warning")<CR>'
	exe "imenu  ".s:Comments.'.&keyword\ comm\..\:W&ORKAROUND\:   <Esc>$:call C_InsertTemplate("comment.keyword-workaround")<CR>'
	exe "imenu  ".s:Comments.'.&keyword\ comm\..\:&new\ keyword\: <Esc>$:call C_InsertTemplate("comment.keyword-keyword")<CR>'
	"
	"----- Submenu : C-Comments : special comments  ----------------------------------------------------------
	"
	exe "amenu  ".s:Comments.'.&special\ comm\..special\ comm\.<Tab>C\/C\+\+  <Nop>'
	exe "amenu  ".s:Comments.'.&special\ comm\..-Sep0-                				<Nop>'
	exe "amenu  ".s:Comments.'.&special\ comm\..&EMPTY                													$:call C_InsertTemplate("comment.special-empty")<CR>'
	exe "amenu  ".s:Comments.'.&special\ comm\..&FALL\ THROUGH        													$:call C_InsertTemplate("comment.special-fall-through")             <CR>'
	exe "amenu  ".s:Comments.'.&special\ comm\..&IMPL\.\ TYPE\ CONV   													$:call C_InsertTemplate("comment.special-implicit-type-conversion") <CR>'
	exe "amenu  ".s:Comments.'.&special\ comm\..&NO\ RETURN           													$:call C_InsertTemplate("comment.special-no-return")                <CR>'
	exe "amenu  ".s:Comments.'.&special\ comm\..NOT\ &REACHED         													$:call C_InsertTemplate("comment.special-not-reached")              <CR>'
	exe "amenu  ".s:Comments.'.&special\ comm\..&TO\ BE\ IMPL\.       													$:call C_InsertTemplate("comment.special-remains-to-be-implemented")<CR>'
	exe "amenu  ".s:Comments.'.&special\ comm\..-SEP81-               :'
	exe "amenu  ".s:Comments.'.&special\ comm\..constant\ type\ is\ &long\ (L)              		$:call C_InsertTemplate("comment.special-constant-type-is-long")<CR>'
	exe "amenu  ".s:Comments.'.&special\ comm\..constant\ type\ is\ &unsigned\ (U)          		$:call C_InsertTemplate("comment.special-constant-type-is-unsigned")<CR>'
	exe "amenu  ".s:Comments.'.&special\ comm\..constant\ type\ is\ unsigned\ l&ong\ (UL)   		$:call C_InsertTemplate("comment.special-constant-type-is-unsigned-long")<CR>'
	"
	exe "imenu  ".s:Comments.'.&special\ comm\..&EMPTY                										 <Esc>$:call C_InsertTemplate("comment.special-empty")<CR>'
	exe "imenu  ".s:Comments.'.&special\ comm\..&FALL\ THROUGH        										 <Esc>$:call C_InsertTemplate("comment.special-fall-through")             <CR>'
	exe "imenu  ".s:Comments.'.&special\ comm\..&IMPL\.\ TYPE\ CONV   										 <Esc>$:call C_InsertTemplate("comment.special-implicit-type-conversion") <CR>'
	exe "imenu  ".s:Comments.'.&special\ comm\..&NO\ RETURN           										 <Esc>$:call C_InsertTemplate("comment.special-no-return")                <CR>'
	exe "imenu  ".s:Comments.'.&special\ comm\..NOT\ &REACHED         										 <Esc>$:call C_InsertTemplate("comment.special-not-reached")              <CR>'
	exe "imenu  ".s:Comments.'.&special\ comm\..&TO\ BE\ IMPL\.       										 <Esc>$:call C_InsertTemplate("comment.special-remains-to-be-implemented")<CR>'
	exe "imenu  ".s:Comments.'.&special\ comm\..-SEP81-               :'
	exe "imenu  ".s:Comments.'.&special\ comm\..constant\ type\ is\ &long\ (L)             <Esc>$:call C_InsertTemplate("comment.special-constant-type-is-long")<CR>'
	exe "imenu  ".s:Comments.'.&special\ comm\..constant\ type\ is\ &unsigned\ (U)         <Esc>$:call C_InsertTemplate("comment.special-constant-type-is-unsigned")<CR>'
	exe "imenu  ".s:Comments.'.&special\ comm\..constant\ type\ is\ unsigned\ l&ong\ (UL)  <Esc>$:call C_InsertTemplate("comment.special-constant-type-is-unsigned-long")<CR>'
	"
	"----- Submenu : C-Comments : Tags  ----------------------------------------------------------
	"
	exe "amenu  ".s:Comments.'.ta&gs\ (plugin).tags\ (plugin)<Tab>C\/C\+\+    <Nop>'
	exe "amenu  ".s:Comments.'.ta&gs\ (plugin).-Sep0-            							<Nop>'
	"
	exe "anoremenu  ".s:Comments.'.ta&gs\ (plugin).&AUTHOR                :call C_InsertMacroValue("AUTHOR")<CR>'
	exe "anoremenu  ".s:Comments.'.ta&gs\ (plugin).AUTHOR&REF             :call C_InsertMacroValue("AUTHORREF")<CR>'
	exe "anoremenu  ".s:Comments.'.ta&gs\ (plugin).&COMPANY               :call C_InsertMacroValue("COMPANY")<CR>'
	exe "anoremenu  ".s:Comments.'.ta&gs\ (plugin).C&OPYRIGHTHOLDER       :call C_InsertMacroValue("COPYRIGHTHOLDER")<CR>'
	exe "anoremenu  ".s:Comments.'.ta&gs\ (plugin).&EMAIL                 :call C_InsertMacroValue("EMAIL")<CR>'
	exe "anoremenu  ".s:Comments.'.ta&gs\ (plugin).&PROJECT               :call C_InsertMacroValue("PROJECT")<CR>'
	"
	exe "inoremenu  ".s:Comments.'.ta&gs\ (plugin).&AUTHOR           <Esc>:call C_InsertMacroValue("AUTHOR")<CR>a'
	exe "inoremenu  ".s:Comments.'.ta&gs\ (plugin).AUTHOR&REF        <Esc>:call C_InsertMacroValue("AUTHORREF")<CR>a'
	exe "inoremenu  ".s:Comments.'.ta&gs\ (plugin).&COMPANY          <Esc>:call C_InsertMacroValue("COMPANY")<CR>a'
	exe "inoremenu  ".s:Comments.'.ta&gs\ (plugin).C&OPYRIGHTHOLDER  <Esc>:call C_InsertMacroValue("COPYRIGHTHOLDER")<CR>a'
	exe "inoremenu  ".s:Comments.'.ta&gs\ (plugin).&EMAIL            <Esc>:call C_InsertMacroValue("EMAIL")<CR>a'
	exe "inoremenu  ".s:Comments.'.ta&gs\ (plugin).&PROJECT          <Esc>:call C_InsertMacroValue("PROJECT")<CR>a'
	"
	exe "vnoremenu  ".s:Comments.'.ta&gs\ (plugin).&AUTHOR          s<Esc>:call C_InsertMacroValue("AUTHOR")<CR>a'
	exe "vnoremenu  ".s:Comments.'.ta&gs\ (plugin).AUTHOR&REF       s<Esc>:call C_InsertMacroValue("AUTHORREF")<CR>a'
	exe "vnoremenu  ".s:Comments.'.ta&gs\ (plugin).&COMPANY         s<Esc>:call C_InsertMacroValue("COMPANY")<CR>a'
	exe "vnoremenu  ".s:Comments.'.ta&gs\ (plugin).C&OPYRIGHTHOLDER s<Esc>:call C_InsertMacroValue("COPYRIGHTHOLDER")<CR>a'
	exe "vnoremenu  ".s:Comments.'.ta&gs\ (plugin).&EMAIL           s<Esc>:call C_InsertMacroValue("EMAIL")<CR>a'
	exe "vnoremenu  ".s:Comments.'.ta&gs\ (plugin).&PROJECT         s<Esc>:call C_InsertMacroValue("PROJECT")<CR>a'
	"
	"
	exe "amenu  ".s:Comments.'.-SEP9-                     :'
	"
	exe " menu  ".s:Comments.'.&date                             <Esc>:call C_InsertDateAndTime("d")<CR>'
	exe "imenu  ".s:Comments.'.&date                             <Esc>:call C_InsertDateAndTime("d")<CR>a'
	exe "vmenu  ".s:Comments.'.&date                            s<Esc>:call C_InsertDateAndTime("d")<CR>a'
	exe " menu  ".s:Comments.'.date\ &time                       <Esc>:call C_InsertDateAndTime("dt")<CR>'
	exe "imenu  ".s:Comments.'.date\ &time                       <Esc>:call C_InsertDateAndTime("dt")<CR>a'
	exe "vmenu  ".s:Comments.'.date\ &time                      s<Esc>:call C_InsertDateAndTime("dt")<CR>a'

	exe "amenu  ".s:Comments.'.-SEP12-                    :'
	exe "amenu <silent> ".s:Comments.'.\/\/\ xxx\ \ \ \ \ &->\ \ \/*\ xxx\ *\/    :call C_CommentCppToC()<CR>'
	exe "vmenu <silent> ".s:Comments.'.\/\/\ xxx\ \ \ \ \ &->\ \ \/*\ xxx\ *\/    <Esc>:'."'<,'>".'call C_CommentCppToC()<CR>'
	exe "amenu <silent> ".s:Comments.'.\/*\ xxx\ *\/\ \ -&>\ \ \/\/\ xxx          :call C_CommentCToCpp()<CR>'
	exe "vmenu <silent> ".s:Comments.'.\/*\ xxx\ *\/\ \ -&>\ \ \/\/\ xxx          <Esc>:'."'<,'>".'call C_CommentCToCpp()<CR>'
	"
	"===============================================================================================
	"----- Menu : C-Statements-------------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_MenuHeader == 'yes'
		exe "amenu  ".s:Statements.'.&Statements<Tab>C\/C\+\+     <Nop>'
		exe "amenu  ".s:Statements.'.-Sep00-                      <Nop>'
	endif
	"
	exe "amenu <silent>".s:Statements.'.&do\ \{\ \}\ while               :call C_InsertTemplate("statements.do-while")<CR>'
	exe "vmenu <silent>".s:Statements.'.&do\ \{\ \}\ while          <Esc>:call C_InsertTemplate("statements.do-while", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.&do\ \{\ \}\ while          <Esc>:call C_InsertTemplate("statements.do-while")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.f&or                             :call C_InsertTemplate("statements.for")<CR>'
	exe "imenu <silent>".s:Statements.'.f&or                        <Esc>:call C_InsertTemplate("statements.for")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.fo&r\ \{\ \}                     :call C_InsertTemplate("statements.for-block")<CR>'
	exe "vmenu <silent>".s:Statements.'.fo&r\ \{\ \}                <Esc>:call C_InsertTemplate("statements.for-block", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.fo&r\ \{\ \}                <Esc>:call C_InsertTemplate("statements.for-block")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.&if                              :call C_InsertTemplate("statements.if")<CR>'
	exe "imenu <silent>".s:Statements.'.&if                         <Esc>:call C_InsertTemplate("statements.if")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.i&f\ \{\ \}                      :call C_InsertTemplate("statements.if-block")<CR>'
	exe "vmenu <silent>".s:Statements.'.i&f\ \{\ \}                 <Esc>:call C_InsertTemplate("statements.if-block", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.i&f\ \{\ \}                 <Esc>:call C_InsertTemplate("statements.if-block")<CR>'

	exe "amenu <silent>".s:Statements.'.if\ &else                        :call C_InsertTemplate("statements.if-else")<CR>'
	exe "vmenu <silent>".s:Statements.'.if\ &else                   <Esc>:call C_InsertTemplate("statements.if-else", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.if\ &else                   <Esc>:call C_InsertTemplate("statements.if-else")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.if\ \{\ \}\ e&lse\ \{\ \}        :call C_InsertTemplate("statements.if-block-else")<CR>'
	exe "vmenu <silent>".s:Statements.'.if\ \{\ \}\ e&lse\ \{\ \}   <Esc>:call C_InsertTemplate("statements.if-block-else", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.if\ \{\ \}\ e&lse\ \{\ \}   <Esc>:call C_InsertTemplate("statements.if-block-else")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.&else\ \{\ \}                    :call C_InsertTemplate("statements.else-block")<CR>'
	exe "vmenu <silent>".s:Statements.'.&else\ \{\ \}               <Esc>:call C_InsertTemplate("statements.else-block", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.&else\ \{\ \}               <Esc>:call C_InsertTemplate("statements.else-block")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.&while                           :call C_InsertTemplate("statements.while")<CR>'
	exe "imenu <silent>".s:Statements.'.&while                      <Esc>:call C_InsertTemplate("statements.while")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.w&hile\ \{\ \}                   :call C_InsertTemplate("statements.while-block")<CR>'
	exe "vmenu <silent>".s:Statements.'.w&hile\ \{\ \}              <Esc>:call C_InsertTemplate("statements.while-block", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.w&hile\ \{\ \}              <Esc>:call C_InsertTemplate("statements.while-block")<CR>'
	"
	exe "amenu <silent>".s:Statements.'.&switch\ \{\ \}                  :call C_InsertTemplate("statements.switch")<CR>'
	exe "vmenu <silent>".s:Statements.'.&switch\ \{\ \}             <Esc>:call C_InsertTemplate("statements.switch", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.&switch\ \{\ \}             <Esc>:call C_InsertTemplate("statements.switch")<CR>'
	"
	exe "amenu  ".s:Statements.'.&case\ \.\.\.\ break                    :call C_InsertTemplate("statements.case")<CR>'
	exe "imenu  ".s:Statements.'.&case\ \.\.\.\ break               <Esc>:call C_InsertTemplate("statements.case")<CR>'
	"
	"
	exe "amenu <silent>".s:Statements.'.&\{\ \}                          :call C_InsertTemplate("statements.block")<CR>'
	exe "vmenu <silent>".s:Statements.'.&\{\ \}                     <Esc>:call C_InsertTemplate("statements.block", "v")<CR>'
	exe "imenu <silent>".s:Statements.'.&\{\ \}                     <Esc>:call C_InsertTemplate("statements.block")<CR>'
	"
	"
	"===============================================================================================
	"----- Menu : C-Idioms ----------------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_MenuHeader == 'yes'
		exe "amenu          ".s:Idioms.'.&Idioms<Tab>C\/C\+\+      <Nop>'
		exe "amenu          ".s:Idioms.'.-Sep00-                   <Nop>'
	endif
	exe "amenu <silent> ".s:Idioms.'.&function                        :call C_InsertTemplate("idioms.function")<CR>'
	exe "vmenu <silent> ".s:Idioms.'.&function                   <Esc>:call C_InsertTemplate("idioms.function", "v")<CR>'
	exe "imenu <silent> ".s:Idioms.'.&function                   <Esc>:call C_InsertTemplate("idioms.function")<CR>'
	exe "amenu <silent> ".s:Idioms.'.s&tatic\ function                :call C_InsertTemplate("idioms.function-static")<CR>'
	exe "vmenu <silent> ".s:Idioms.'.s&tatic\ function           <Esc>:call C_InsertTemplate("idioms.function-static", "v")<CR>'
	exe "imenu <silent> ".s:Idioms.'.s&tatic\ function           <Esc>:call C_InsertTemplate("idioms.function-static")<CR>'
	exe "amenu <silent> ".s:Idioms.'.&main                            :call C_InsertTemplate("idioms.main")<CR>'
	exe "vmenu <silent> ".s:Idioms.'.&main                       <Esc>:call C_InsertTemplate("idioms.main", "v")<CR>'
	exe "imenu <silent> ".s:Idioms.'.&main                       <Esc>:call C_InsertTemplate("idioms.main")<CR>'

	exe "amenu          ".s:Idioms.'.-SEP1-                      :'
	exe "amenu          ".s:Idioms.'.for(x=&0;\ x<n;\ x\+=1)          :call C_CodeFor("up"  , "a")<CR>'
	exe "amenu          ".s:Idioms.'.for(x=&n-1;\ x>=0;\ x\-=1)       :call C_CodeFor("down", "a")<CR>'
	exe "vmenu          ".s:Idioms.'.for(x=&0;\ x<n;\ x\+=1)     <Esc>:call C_CodeFor("up"  , "v")<CR>'
	exe "vmenu          ".s:Idioms.'.for(x=&n-1;\ x>=0;\ x\-=1)  <Esc>:call C_CodeFor("down", "v")<CR>'
	exe "imenu          ".s:Idioms.'.for(x=&0;\ x<n;\ x\+=1)     <Esc>:call C_CodeFor("up"  , "a")<CR>i'
	exe "imenu          ".s:Idioms.'.for(x=&n-1;\ x>=0;\ x\-=1)  <Esc>:call C_CodeFor("down", "a")<CR>i'

	exe "amenu          ".s:Idioms.'.-SEP2-                      :'
	exe "amenu <silent> ".s:Idioms.'.&enum                            :call C_InsertTemplate("idioms.enum")<CR>'
	exe "amenu <silent> ".s:Idioms.'.&struct                          :call C_InsertTemplate("idioms.struct")<CR>'
	exe "amenu <silent> ".s:Idioms.'.&union                           :call C_InsertTemplate("idioms.union")<CR>'
	exe "vmenu <silent> ".s:Idioms.'.&enum                       <Esc>:call C_InsertTemplate("idioms.enum"  , "v")<CR>'
	exe "vmenu <silent> ".s:Idioms.'.&struct                     <Esc>:call C_InsertTemplate("idioms.struct", "v")<CR>'
	exe "vmenu <silent> ".s:Idioms.'.&union                      <Esc>:call C_InsertTemplate("idioms.union" , "v")<CR>'
	exe "imenu <silent> ".s:Idioms.'.&enum                       <Esc>:call C_InsertTemplate("idioms.enum"  )<CR>'
	exe "imenu <silent> ".s:Idioms.'.&struct                     <Esc>:call C_InsertTemplate("idioms.struct")<CR>'
	exe "imenu <silent> ".s:Idioms.'.&union                      <Esc>:call C_InsertTemplate("idioms.union" )<CR>'
	exe "amenu          ".s:Idioms.'.-SEP3-                      :'
	"
	exe "amenu <silent> ".s:Idioms.'.scanf                            :call C_InsertTemplate("idioms.scanf")<CR>'
	exe "amenu <silent> ".s:Idioms.'.printf                           :call C_InsertTemplate("idioms.printf")<CR>'
	exe "imenu <silent> ".s:Idioms.'.scanf                       <Esc>:call C_InsertTemplate("idioms.scanf")<CR>'
	exe "imenu <silent> ".s:Idioms.'.printf                      <Esc>:call C_InsertTemplate("idioms.printf")<CR>'
	"
	exe "amenu          ".s:Idioms.'.-SEP4-                       :'
	exe "amenu <silent> ".s:Idioms.'.p=ca&lloc\(n,sizeof(type)\)      :call C_InsertTemplate("idioms.calloc")<CR>'
	exe "amenu <silent> ".s:Idioms.'.p=m&alloc\(sizeof(type)\)        :call C_InsertTemplate("idioms.malloc")<CR>'
	exe "imenu <silent> ".s:Idioms.'.p=ca&lloc\(n,sizeof(type)\) <Esc>:call C_InsertTemplate("idioms.calloc")<CR>'
	exe "imenu <silent> ".s:Idioms.'.p=m&alloc\(sizeof(type)\)   <Esc>:call C_InsertTemplate("idioms.malloc")<CR>'
	"
	exe "anoremenu <silent> ".s:Idioms.'.si&zeof(\ \)                 :call C_InsertTemplate("idioms.sizeof")<CR>'
	exe "inoremenu <silent> ".s:Idioms.'.si&zeof(\ \)            <Esc>:call C_InsertTemplate("idioms.sizeof")<CR>'
	exe "vnoremenu <silent> ".s:Idioms.'.si&zeof(\ \)            <Esc>:call C_InsertTemplate("idioms.sizeof", "v")<CR>'
	"
	exe "anoremenu <silent> ".s:Idioms.'.asse&rt(\ \)                 :call C_InsertTemplate("idioms.assert")<CR>'
	exe "inoremenu <silent> ".s:Idioms.'.asse&rt(\ \)            <Esc>:call C_InsertTemplate("idioms.assert")<CR>'
	exe "vnoremenu <silent> ".s:Idioms.'.asse&rt(\ \)            <Esc>:call C_InsertTemplate("idioms.assert", "v")<CR>'

	exe "amenu          ".s:Idioms.'.-SEP5-                      :'
	exe "amenu <silent> ".s:Idioms.'.open\ &input\ file               :call C_InsertTemplate("idioms.open-input-file")<CR>'
	exe "imenu <silent> ".s:Idioms.'.open\ &input\ file          <Esc>:call C_InsertTemplate("idioms.open-input-file")<CR>'
	exe "vmenu <silent> ".s:Idioms.'.open\ &input\ file          <Esc>:call C_InsertTemplate("idioms.open-input-file", "v")<CR>'
	exe "amenu <silent> ".s:Idioms.'.open\ &output\ file              :call C_InsertTemplate("idioms.open-output-file")<CR>'
	exe "imenu <silent> ".s:Idioms.'.open\ &output\ file         <Esc>:call C_InsertTemplate("idioms.open-output-file")<CR>'
	exe "vmenu <silent> ".s:Idioms.'.open\ &output\ file         <Esc>:call C_InsertTemplate("idioms.open-output-file", "v")<CR>'
	"
	exe "amenu <silent> ".s:Idioms.'.fscanf                           :call C_InsertTemplate("idioms.fscanf")<CR>'
	exe "amenu <silent> ".s:Idioms.'.fprintf                          :call C_InsertTemplate("idioms.fprintf")<CR>'
	exe "imenu <silent> ".s:Idioms.'.fscanf                      <Esc>:call C_InsertTemplate("idioms.fscanf")<CR>'
	exe "imenu <silent> ".s:Idioms.'.fprintf                     <Esc>:call C_InsertTemplate("idioms.fprintf")<CR>'
	"
	"===============================================================================================
	"----- Menu : C-Preprocessor ----------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_MenuHeader == 'yes'
		exe "amenu  ".s:Preprocessor.'.&Preprocessor<Tab>C\/C\+\+   <Nop>'
		exe "amenu  ".s:Preprocessor.'.-Sep00-                      <Nop>'
	endif
	"
	"----- Submenu : C-Idioms: standard library -------------------------------------------------------
	"'
	exe "amenu  ".s:Preprocessor.'.#include\ &Std\.Lib\..Std\.Lib\.<Tab>C\/C\+\+  <Nop>'
	exe "amenu  ".s:Preprocessor.'.#include\ &Std\.Lib\..-Sep0-         					<Nop>'
	call C_CIncludeMenus ( s:Preprocessor.'.#include\ &Std\.Lib\.', s:C_StandardLibs )
	"
	exe "anoremenu  ".s:Preprocessor.'.#include\ C&99.C99<Tab>C\/C\+\+         		<Nop>'
	exe "anoremenu  ".s:Preprocessor.'.#include\ C&99.-Sep0-                			<Nop>'
	call C_CIncludeMenus ( s:Preprocessor.'.#include\ C&99', s:C_C99Libs )
	"
	exe "amenu  ".s:Preprocessor.'.-SEP2-                        :'
	exe "anoremenu  ".s:Preprocessor.'.#include\ &\<\.\.\.\>           :call C_InsertTemplate("preprocessor.include-global")<CR>'
	exe "anoremenu  ".s:Preprocessor.'.#include\ &\"\.\.\.\"           :call C_InsertTemplate("preprocessor.include-local")<CR>'
	exe "amenu  ".s:Preprocessor.'.#&define                            :call C_InsertTemplate("preprocessor.define")<CR>'
	exe "amenu  ".s:Preprocessor.'.&#undef                             :call C_InsertTemplate("preprocessor.undefine")<CR>'
	"
	exe "inoremenu  ".s:Preprocessor.'.#include\ &\<\.\.\.\>      <Esc>:call C_InsertTemplate("preprocessor.include-global")<CR>'
	exe "inoremenu  ".s:Preprocessor.'.#include\ &\"\.\.\.\"      <Esc>:call C_InsertTemplate("preprocessor.include-local")<CR>'
	exe "imenu  ".s:Preprocessor.'.#&define                       <Esc>:call C_InsertTemplate("preprocessor.define")<CR>'
	exe "imenu  ".s:Preprocessor.'.&#undef                        <Esc>:call C_InsertTemplate("preprocessor.undefine")<CR>'
	"
	exe "amenu  ".s:Preprocessor.'.#&if\ #else\ #endif                 :call C_InsertTemplate("preprocessor.if-else-endif")<CR>'
	exe "amenu  ".s:Preprocessor.'.#i&fdef\ #else\ #endif              :call C_InsertTemplate("preprocessor.ifdef-else-endif")<CR>'
	exe "amenu  ".s:Preprocessor.'.#if&ndef\ #else\ #endif             :call C_InsertTemplate("preprocessor.ifndef-else-endif")<CR>'
	exe "amenu  ".s:Preprocessor.'.#ifnd&ef\ #def\ #endif              :call C_InsertTemplate("preprocessor.ifndef-def-endif")<CR>'
	"
	exe "imenu  ".s:Preprocessor.'.#&if\ #else\ #endif            <Esc>:call C_InsertTemplate("preprocessor.if-else-endif")<CR>'
	exe "imenu  ".s:Preprocessor.'.#i&fdef\ #else\ #endif         <Esc>:call C_InsertTemplate("preprocessor.ifdef-else-endif")<CR>'
	exe "imenu  ".s:Preprocessor.'.#if&ndef\ #else\ #endif        <Esc>:call C_InsertTemplate("preprocessor.ifndef-else-endif")<CR>'
	exe "imenu  ".s:Preprocessor.'.#ifnd&ef\ #def\ #endif         <Esc>:call C_InsertTemplate("preprocessor.ifndef-def-endif")<CR>'
	"
	exe "vmenu  ".s:Preprocessor.'.#&if\ #else\ #endif            <Esc>:call C_InsertTemplate("preprocessor.if-else-endif", "v")<CR>'
	exe "vmenu  ".s:Preprocessor.'.#i&fdef\ #else\ #endif         <Esc>:call C_InsertTemplate("preprocessor.ifdef-else-endif", "v")<CR>'
	exe "vmenu  ".s:Preprocessor.'.#if&ndef\ #else\ #endif        <Esc>:call C_InsertTemplate("preprocessor.ifndef-else-endif", "v")<CR>'
	exe "vmenu  ".s:Preprocessor.'.#ifnd&ef\ #def\ #endif         <Esc>:call C_InsertTemplate("preprocessor.ifndef-def-endif", "v")<CR>'

	exe "amenu  ".s:Preprocessor.'.#if\ &0\ #endif                     :call C_PPIf0("a")<CR>2ji'
	exe "imenu  ".s:Preprocessor.'.#if\ &0\ #endif                <Esc>:call C_PPIf0("a")<CR>2ji'
	exe "vmenu  ".s:Preprocessor.'.#if\ &0\ #endif                <Esc>:call C_PPIf0("v")<CR>'
	"
	exe "amenu <silent> ".s:Preprocessor.'.&remove\ #if\ 0\ #endif             :call C_PPIf0Remove()<CR>'
	exe "imenu <silent> ".s:Preprocessor.'.&remove\ #if\ 0\ #endif        <Esc>:call C_PPIf0Remove()<CR>'
	"
	exe "amenu  ".s:Preprocessor.'.#err&or                             :call C_InsertTemplate("preprocessor.error")<CR>'
	exe "amenu  ".s:Preprocessor.'.#&line                              :call C_InsertTemplate("preprocessor.line")<CR>'
	exe "amenu  ".s:Preprocessor.'.#&pragma                            :call C_InsertTemplate("preprocessor.pragma")<CR>'
	exe "imenu  ".s:Preprocessor.'.#err&or                        <C-C>:call C_InsertTemplate("preprocessor.error")<CR>'
	exe "imenu  ".s:Preprocessor.'.#&line                         <C-C>:call C_InsertTemplate("preprocessor.line")<CR>'
	exe "imenu  ".s:Preprocessor.'.#&pragma                       <C-C>:call C_InsertTemplate("preprocessor.pragma")<CR>'
	"
	"===============================================================================================
	"----- Menu : Snippets ----------------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_MenuHeader == 'yes'
		exe "amenu           ".s:Snippets.'.S&nippets<Tab>C\/C\+\+       <Nop>'
		exe "amenu           ".s:Snippets.'.-Sep00-                      <Nop>'
	endif
	if s:C_CodeSnippets != ""
		exe "amenu  <silent> ".s:Snippets.'.&read\ code\ snippet       :call C_CodeSnippet("r")<CR>'
		exe "amenu  <silent> ".s:Snippets.'.&write\ code\ snippet      :call C_CodeSnippet("w")<CR>'
		exe "amenu  <silent> ".s:Snippets.'.&edit\ code\ snippet       :call C_CodeSnippet("e")<CR>'
		exe "imenu  <silent> ".s:Snippets.'.&read\ code\ snippet  <C-C>:call C_CodeSnippet("r")<CR>'
		exe "imenu  <silent> ".s:Snippets.'.&write\ code\ snippet <C-C>:call C_CodeSnippet("w")<CR>'
		exe "imenu  <silent> ".s:Snippets.'.&edit\ code\ snippet  <C-C>:call C_CodeSnippet("e")<CR>'
		exe "vmenu  <silent> ".s:Snippets.'.&write\ code\ snippet <C-C>:call C_CodeSnippet("wv")<CR>'
		exe " menu  <silent> ".s:Snippets.'.-SEP1-								:'
	endif
	exe " menu  <silent> ".s:Snippets.'.&pick\ up\ prototype   	     :call C_ProtoPick("n")<CR>'
	exe " menu  <silent> ".s:Snippets.'.&insert\ prototype(s)  	     :call C_ProtoInsert()<CR>'
	exe " menu  <silent> ".s:Snippets.'.&clear\ prototype(s)		     :call C_ProtoClear()<CR>'
	exe " menu  <silent> ".s:Snippets.'.&show\ prototype(s)			     :call C_ProtoShow()<CR>'
	exe "imenu  <silent> ".s:Snippets.'.&pick\ up\ prototype   	<C-C>:call C_ProtoPick("n")<CR>'
	exe "imenu  <silent> ".s:Snippets.'.&insert\ prototype(s)  	<C-C>:call C_ProtoInsert()<CR>'
	exe "imenu  <silent> ".s:Snippets.'.&clear\ prototype(s)		<C-C>:call C_ProtoClear()<CR>'
	exe "imenu  <silent> ".s:Snippets.'.&show\ prototype(s)			<C-C>:call C_ProtoShow()<CR>'
	exe "vmenu  <silent> ".s:Snippets.'.&pick\ up\ prototype   	<C-C>:call C_ProtoPick("v")<CR>'

	exe " menu  <silent> ".s:Snippets.'.-SEP2-									     :'
	exe "amenu  <silent>  ".s:Snippets.'.edit\ &local\ templates          :call C_EditTemplates("local")<CR>'
	exe "amenu  <silent>  ".s:Snippets.'.edit\ &global\ templates         :call C_EditTemplates("global")<CR>'
	exe "amenu  <silent>  ".s:Snippets.'.reread\ &templates               :call C_RereadTemplates()<CR>'
	exe "imenu  <silent>  ".s:Snippets.'.edit\ &local\ templates     <C-C>:call C_EditTemplates("local")<CR>'
	exe "imenu  <silent>  ".s:Snippets.'.edit\ &global\ templates    <C-C>:call C_EditTemplates("global")<CR>'
	exe "imenu  <silent>  ".s:Snippets.'.reread\ &templates          <C-C>:call C_RereadTemplates()<CR>'
	"
	"===============================================================================================
	"----- Menu : C++ ---------------------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_MenuHeader == 'yes'
		exe "amenu  ".s:Cpp.'.C&\+\+<Tab>C\/C\+\+         <Nop>'
		exe "amenu  ".s:Cpp.'.-Sep00-                     <Nop>'
	endif
	exe "anoremenu ".s:Cpp.'.c&in                      :call C_InsertTemplate("cpp.cin")<CR>'
	exe "anoremenu ".s:Cpp.'.c&out                     :call C_InsertTemplate("cpp.cout")<CR>'
	exe "anoremenu ".s:Cpp.'.<<\ &\"\"                 :call C_InsertTemplate("cpp.cout-operator")<CR>'
	exe "inoremenu ".s:Cpp.'.c&in                 <Esc>:call C_InsertTemplate("cpp.cin")<CR>'
	exe "inoremenu ".s:Cpp.'.c&out                <Esc>:call C_InsertTemplate("cpp.cout")<CR>'
	exe "inoremenu ".s:Cpp.'.<<\ &\"\"            <Esc>:call C_InsertTemplate("cpp.cout-operator")<CR>'
	"
	"----- Submenu : C++ : output manipulators  -------------------------------------------------------
	"
	exe "amenu ".s:Cpp.'.&output\ manipulators.output\ manip\.<Tab>C\/C\+\+   <Nop>'
	exe "amenu ".s:Cpp.'.&output\ manipulators.-Sep0-                     		<Nop>'
	"
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &boolalpha                :call C_InsertTemplate("cpp.output-manipulator-boolalpha")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &dec                      :call C_InsertTemplate("cpp.output-manipulator-dec")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &endl                     :call C_InsertTemplate("cpp.output-manipulator-endl")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &fixed                    :call C_InsertTemplate("cpp.output-manipulator-fixed")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ fl&ush                    :call C_InsertTemplate("cpp.output-manipulator-flush")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &hex                      :call C_InsertTemplate("cpp.output-manipulator-hex")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &internal                 :call C_InsertTemplate("cpp.output-manipulator-internal")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &left                     :call C_InsertTemplate("cpp.output-manipulator-left")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &oct                      :call C_InsertTemplate("cpp.output-manipulator-oct")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &right                    :call C_InsertTemplate("cpp.output-manipulator-right")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ s&cientific               :call C_InsertTemplate("cpp.output-manipulator-scientific")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &setbase\(\ \)            :call C_InsertTemplate("cpp.output-manipulator-setbase")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ se&tfill\(\ \)            :call C_InsertTemplate("cpp.output-manipulator-setfill")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ setiosfla&g\(\ \)         :call C_InsertTemplate("cpp.output-manipulator-setiosflags")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ set&precision\(\ \)       :call C_InsertTemplate("cpp.output-manipulator-setprecision")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ set&w\(\ \)               :call C_InsertTemplate("cpp.output-manipulator-setw")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ showb&ase                 :call C_InsertTemplate("cpp.output-manipulator-showbase")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ showpoi&nt                :call C_InsertTemplate("cpp.output-manipulator-showpoint")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ showpos\ \(&1\)           :call C_InsertTemplate("cpp.output-manipulator-showpos")<CR>'
	exe "anoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ uppercase\ \(&2\)         :call C_InsertTemplate("cpp.output-manipulator-uppercase")<CR>'
	"
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &boolalpha           <Esc>:call C_InsertTemplate("cpp.output-manipulator-boolalpha")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &dec                 <Esc>:call C_InsertTemplate("cpp.output-manipulator-dec")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &endl                <Esc>:call C_InsertTemplate("cpp.output-manipulator-endl")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &fixed               <Esc>:call C_InsertTemplate("cpp.output-manipulator-fixed")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ fl&ush               <Esc>:call C_InsertTemplate("cpp.output-manipulator-flush")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &hex                 <Esc>:call C_InsertTemplate("cpp.output-manipulator-hex")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &internal            <Esc>:call C_InsertTemplate("cpp.output-manipulator-internal")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &left                <Esc>:call C_InsertTemplate("cpp.output-manipulator-left")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &oct                 <Esc>:call C_InsertTemplate("cpp.output-manipulator-oct")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &right               <Esc>:call C_InsertTemplate("cpp.output-manipulator-right")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ s&cientific          <Esc>:call C_InsertTemplate("cpp.output-manipulator-scientific")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ &setbase\(\ \)       <Esc>:call C_InsertTemplate("cpp.output-manipulator-setbase")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ se&tfill\(\ \)       <Esc>:call C_InsertTemplate("cpp.output-manipulator-setfill")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ setiosfla&g\(\ \)    <Esc>:call C_InsertTemplate("cpp.output-manipulator-setiosflags")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ set&precision\(\ \)  <Esc>:call C_InsertTemplate("cpp.output-manipulator-setprecision")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ set&w\(\ \)          <Esc>:call C_InsertTemplate("cpp.output-manipulator-setw")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ showb&ase            <Esc>:call C_InsertTemplate("cpp.output-manipulator-showbase")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ showpoi&nt           <Esc>:call C_InsertTemplate("cpp.output-manipulator-showpoint")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ showpos\ \(&1\)      <Esc>:call C_InsertTemplate("cpp.output-manipulator-showpos")<CR>'
	exe "inoremenu ".s:Cpp.'.&output\ manipulators.\<\<\ uppercase\ \(&2\)    <Esc>:call C_InsertTemplate("cpp.output-manipulator-uppercase")<CR>'
	"
	"----- Submenu : C++ : ios flag bits  -------------------------------------------------------------
	"
	exe "amenu ".s:Cpp.'.ios\ flag&bits.ios\ flags<Tab>C\/C\+\+       <Nop>'
	exe "amenu ".s:Cpp.'.ios\ flag&bits.-Sep0-               					<Nop>'
	"
	call C_CIosFlagMenus ( s:Cpp.'.ios\ flag&bits', s:Cpp_IosFlagBits )
	"
	"----- Submenu : C++   library  (algorithm - locale) ----------------------------------------------
	"
	exe "amenu ".s:Cpp.'.#include\ <alg\.\.loc>\ \(&1\).alg\.\.loc<Tab>C\/C\+\+   <Nop>'
	exe "amenu ".s:Cpp.'.#include\ <alg\.\.loc>\ \(&1\).-Sep0-          					<Nop>'
	call C_CIncludeMenus ( s:Cpp.'.#include\ <alg\.\.loc>\ \(&1\)', s:Cpp_StandardLibs1 )
	"
	"----- Submenu : C++   library  (map - vector) ----------------------------------------------------
	"
	exe "amenu ".s:Cpp.'.#include\ <map\.\.vec>\ \(&2\).map\.\.vec<Tab>C\/C\+\+   <Nop>'
	exe "amenu ".s:Cpp.'.#include\ <map\.\.vec>\ \(&2\).-Sep0-          					<Nop>'
	call C_CIncludeMenus ( s:Cpp.'.#include\ <map\.\.vec>\ \(&2\)', s:Cpp_StandardLibs2 )
	"
	"----- Submenu : C     library  (cassert - ctime) -------------------------------------------------
	"
	exe "amenu ".s:Cpp.'.#include\ <cX>\ \(&3\).cX<Tab>C\/C\+\+ 	<Nop>'
	exe "amenu ".s:Cpp.'.#include\ <cX>\ \(&3\).-Sep0-        		<Nop>'
	call C_CIncludeMenus ( s:Cpp.'.#include\ <cX>\ \(&3\)', s:Cpp_StandardLibs3 )
	"
	"----- End Submenu : C     library  (cassert - ctime) ---------------------------------------------
	"
	exe "amenu <silent> ".s:Cpp.'.-SEP2-                        :'

	exe "amenu <silent> ".s:Cpp.'.&class                             :call C_InsertTemplate("cpp.class-definition")<CR>'
	exe "amenu <silent> ".s:Cpp.'.class\ (w\.\ &new)                 :call C_InsertTemplate("cpp.class-using-new-definition")<CR>'
	exe "amenu <silent> ".s:Cpp.'.&templ\.\ class                    :call C_InsertTemplate("cpp.template-class-definition")<CR>'
	exe "amenu <silent> ".s:Cpp.'.templ\.\ class\ (w\.\ ne&w)        :call C_InsertTemplate("cpp.template-class-using-new-definition")<CR>'

	exe "imenu <silent> ".s:Cpp.'.&class                        <Esc>:call C_InsertTemplate("cpp.class-definition")<CR>'
	exe "imenu <silent> ".s:Cpp.'.class\ (w\.\ &new)            <Esc>:call C_InsertTemplate("cpp.class-using-new-definition")<CR>'
	exe "imenu <silent> ".s:Cpp.'.&templ\.\ class               <Esc>:call C_InsertTemplate("cpp.template-class-definition")<CR>'
	exe "imenu <silent> ".s:Cpp.'.templ\.\ class\ (w\.\ ne&w)   <Esc>:call C_InsertTemplate("cpp.template-class-using-new-definition")<CR>'

	"
	"----- Submenu : C++ : IMPLEMENTATION  -------------------------------------------------------
	"
	exe "amenu ".s:Cpp.'.IM&PLEMENTATION.IMPLEMENT\.<Tab>C\/C\+\+   <Nop>'
	exe "amenu ".s:Cpp.'.IM&PLEMENTATION.-Sep0-                     <Nop>'
	"
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.&class             					     :call C_InsertTemplate("cpp.class-implementation")<CR>'
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.class\ (w\.\ &new)     			     :call C_InsertTemplate("cpp.class-using-new-implementation")<CR>'
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.&method                   	     :call C_InsertTemplate("cpp.method-implementation")<CR>'
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.&accessor                		     :call C_InsertTemplate("cpp.accessor-implementation")<CR>'
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.-SEP21-                   	:'
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.&templ\.\ class           	     :call C_InsertTemplate("cpp.template-class-implementation")<CR>'
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.templ\.\ class\ (w\.\ ne&w)      :call C_InsertTemplate("cpp.template-class-using-new-implementation")<CR>'
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.templ\.\ m&ethod          	     :call C_InsertTemplate("cpp.template-method-implementation")<CR>'
	exe "amenu <silent> ".s:Cpp.'.IM&PLEMENTATION.templ\.\ a&ccessor         	     :call C_InsertTemplate("cpp.template-accessor-implementation")<CR>'
	"
	exe "imenu <silent> ".s:Cpp.'.IM&PLEMENTATION.&class             					<Esc>:call C_InsertTemplate("cpp.class-implementation")<CR>'
	exe "imenu <silent> ".s:Cpp.'.IM&PLEMENTATION.class\ (w\.\ &new)     			<Esc>:call C_InsertTemplate("cpp.class-using-new-implementation")<CR>'
	exe "imenu <silent> ".s:Cpp.'.IM&PLEMENTATION.&method                   	<Esc>:call C_InsertTemplate("cpp.method-implementation")<CR>'
	exe "imenu <silent> ".s:Cpp.'.IM&PLEMENTATION.&accessor                		<Esc>:call C_InsertTemplate("cpp.accessor-implementation")<CR>'
	"
	exe "imenu <silent> ".s:Cpp.'.IM&PLEMENTATION.&templ\.\ class           	<Esc>:call C_InsertTemplate("cpp.template-class-implementation")<CR>'
	exe "imenu <silent> ".s:Cpp.'.IM&PLEMENTATION.templ\.\ class\ (w\.\ ne&w) <Esc>:call C_InsertTemplate("cpp.template-class-using-new-implementation")<CR>'
	exe "imenu <silent> ".s:Cpp.'.IM&PLEMENTATION.templ\.\ m&ethod          	<Esc>:call C_InsertTemplate("cpp.template-method-implementation")<CR>'
	exe "imenu <silent> ".s:Cpp.'.IM&PLEMENTATION.templ\.\ a&ccessor         	<Esc>:call C_InsertTemplate("cpp.template-accessor-implementation")<CR>'
	"
	"----- End Submenu : C++ : IMPLEMENTATION  -------------------------------------------------------
	"
	exe "amenu <silent> ".s:Cpp.'.-SEP31-                       :'
	exe "amenu <silent> ".s:Cpp.'.templ\.\ &function                 :call C_InsertTemplate("cpp.template-function")<CR>'
	exe "amenu <silent> ".s:Cpp.'.&error\ class                      :call C_InsertTemplate("cpp.error-class")<CR>'
	exe "imenu <silent> ".s:Cpp.'.templ\.\ &function            <Esc>:call C_InsertTemplate("cpp.template-function")<CR>'
	exe "imenu <silent> ".s:Cpp.'.&error\ class                 <Esc>:call C_InsertTemplate("cpp.error-class")<CR>'

	exe "amenu <silent> ".s:Cpp.'.-SEP4-                        :'
	exe "amenu <silent> ".s:Cpp.'.operator\ &<<                      :call C_InsertTemplate("cpp.operator-in")<CR>'
	exe "amenu <silent> ".s:Cpp.'.operator\ &>>                      :call C_InsertTemplate("cpp.operator-out")<CR>'
	exe "imenu <silent> ".s:Cpp.'.operator\ &<<                 <Esc>:call C_InsertTemplate("cpp.operator-in")<CR>'
	exe "imenu <silent> ".s:Cpp.'.operator\ &>>                 <Esc>:call C_InsertTemplate("cpp.operator-out")<CR>'
	exe "amenu <silent> ".s:Cpp.'.-SEP5-                        :'
	exe "amenu <silent> ".s:Cpp.'.tr&y\ \.\.\ catch                  :call C_InsertTemplate("cpp.try-catch")<CR>'
	exe "imenu <silent> ".s:Cpp.'.tr&y\ \.\.\ catch             <Esc>:call C_InsertTemplate("cpp.try-catch")<CR>'
	exe "vmenu <silent> ".s:Cpp.'.tr&y\ \.\.\ catch             <Esc>:call C_InsertTemplate("cpp.try-catch", "v")<CR>'
	exe "amenu <silent> ".s:Cpp.'.catc&h                             :call C_InsertTemplate("cpp.catch")<CR>'
	exe "imenu <silent> ".s:Cpp.'.catc&h                        <Esc>:call C_InsertTemplate("cpp.catch")<CR>'
	exe "vmenu <silent> ".s:Cpp.'.catc&h                        <Esc>:call C_InsertTemplate("cpp.catch", "v")<CR>'

	exe "amenu <silent> ".s:Cpp.'.catch\(&\.\.\.\)                   :call C_InsertTemplate("cpp.catch-points")<CR>'
	exe "imenu <silent> ".s:Cpp.'.catch\(&\.\.\.\)              <Esc>:call C_InsertTemplate("cpp.catch-points")<CR>'
	exe "vmenu <silent> ".s:Cpp.'.catch\(&\.\.\.\)              <Esc>:call C_InsertTemplate("cpp.catch-points", "v")<CR>'

	exe "amenu <silent> ".s:Cpp.'.-SEP6-                        :'
	exe "amenu <silent> ".s:Cpp.'.open\ input\ file\ \ \(&4\)        :call C_InsertTemplate("cpp.open-input-file")<CR>'
	exe "imenu <silent> ".s:Cpp.'.open\ input\ file\ \ \(&4\)   <Esc>:call C_InsertTemplate("cpp.open-input-file")<CR>'
	exe "vmenu <silent> ".s:Cpp.'.open\ input\ file\ \ \(&4\)   <Esc>:call C_InsertTemplate("cpp.open-input-file", "v")<CR>'
	exe "amenu <silent> ".s:Cpp.'.open\ output\ file\ \(&5\)         :call C_InsertTemplate("cpp.open-output-file")<CR>'
	exe "imenu <silent> ".s:Cpp.'.open\ output\ file\ \(&5\)    <Esc>:call C_InsertTemplate("cpp.open-output-file")<CR>'
	exe "vmenu <silent> ".s:Cpp.'.open\ output\ file\ \(&5\)    <Esc>:call C_InsertTemplate("cpp.open-output-file", "v")<CR>'
	exe "amenu <silent> ".s:Cpp.'.-SEP7-                        :'

	exe "amenu <silent> ".s:Cpp.'.&using\ namespace\ std;            :call C_InsertTemplate("cpp.namespace-std")<CR>'
	exe "imenu <silent> ".s:Cpp.'.&using\ namespace\ std;       <Esc>:call C_InsertTemplate("cpp.namespace-std")<CR>'
	exe "amenu <silent> ".s:Cpp.'.usin&g\ namespace\ xxx;            :call C_InsertTemplate("cpp.namespace")<CR>'
	exe "imenu <silent> ".s:Cpp.'.usin&g\ namespace\ xxx;       <Esc>:call C_InsertTemplate("cpp.namespace")<CR>'

	exe "amenu <silent> ".s:Cpp.'.namespace\ xxx\ &\{\ \}            :call C_InsertTemplate("cpp.namespace-block")<CR>'
	exe "imenu <silent> ".s:Cpp.'.namespace\ xxx\ &\{\ \}       <Esc>:call C_InsertTemplate("cpp.namespace-block")<CR>'
	exe "vmenu <silent> ".s:Cpp.'.namespace\ xxx\ &\{\ \}       <Esc>:call C_InsertTemplate("cpp.namespace-block", "v")<CR>'

	exe "amenu <silent> ".s:Cpp.'.-SEP8-              :'
	"
	"----- Submenu : RTTI  ----------------------------------------------------------------------------
	"
	exe "amenu ".s:Cpp.'.&RTTI.RTTI<Tab>C\/C\+\+      <Nop>'
	exe "amenu ".s:Cpp.'.&RTTI.-Sep0-                 <Nop>'
	"
	exe "anoremenu ".s:Cpp.'.&RTTI.&typeid                     :call C_InsertTemplate("cpp.rtti-typeid")<CR>'
	exe "anoremenu ".s:Cpp.'.&RTTI.&static_cast                :call C_InsertTemplate("cpp.rtti-static-cast")<CR>'
	exe "anoremenu ".s:Cpp.'.&RTTI.&const_cast                 :call C_InsertTemplate("cpp.rtti-const-cast")<CR>'
	exe "anoremenu ".s:Cpp.'.&RTTI.&reinterpret_cast           :call C_InsertTemplate("cpp.rtti-reinterpret-cast")<CR>'
	exe "anoremenu ".s:Cpp.'.&RTTI.&dynamic_cast               :call C_InsertTemplate("cpp.rtti-dynamic-cast")<CR>'
	"
	exe "inoremenu ".s:Cpp.'.&RTTI.&typeid                <Esc>:call C_InsertTemplate("cpp.rtti-typeid")<CR>'
	exe "inoremenu ".s:Cpp.'.&RTTI.&static_cast           <Esc>:call C_InsertTemplate("cpp.rtti-static-cast")<CR>'
	exe "inoremenu ".s:Cpp.'.&RTTI.&const_cast            <Esc>:call C_InsertTemplate("cpp.rtti-const-cast")<CR>'
	exe "inoremenu ".s:Cpp.'.&RTTI.&reinterpret_cast      <Esc>:call C_InsertTemplate("cpp.rtti-reinterpret-cast")<CR>'
	exe "inoremenu ".s:Cpp.'.&RTTI.&dynamic_cast          <Esc>:call C_InsertTemplate("cpp.rtti-dynamic-cast")<CR>'
	"
	exe "vnoremenu ".s:Cpp.'.&RTTI.&typeid                <Esc>:call C_InsertTemplate("cpp.rtti-typeid", "v")<CR>'
	exe "vnoremenu ".s:Cpp.'.&RTTI.&static_cast           <Esc>:call C_InsertTemplate("cpp.rtti-static-cast", "v")<CR>'
	exe "vnoremenu ".s:Cpp.'.&RTTI.&const_cast            <Esc>:call C_InsertTemplate("cpp.rtti-const-cast", "v")<CR>'
	exe "vnoremenu ".s:Cpp.'.&RTTI.&reinterpret_cast      <Esc>:call C_InsertTemplate("cpp.rtti-reinterpret-cast", "v")<CR>'
	exe "vnoremenu ".s:Cpp.'.&RTTI.&dynamic_cast          <Esc>:call C_InsertTemplate("cpp.rtti-dynamic-cast", "v")<CR>'
	"
	"----- End Submenu : RTTI  ------------------------------------------------------------------------
	"
	exe "amenu  <silent>".s:Cpp.'.e&xtern\ \"C\"\ \{\ \}       :call C_InsertTemplate("cpp.extern")<CR>'
	exe "imenu  <silent>".s:Cpp.'.e&xtern\ \"C\"\ \{\ \}  <Esc>:call C_InsertTemplate("cpp.extern")<CR>'
	exe "vmenu  <silent>".s:Cpp.'.e&xtern\ \"C\"\ \{\ \}  <Esc>:call C_InsertTemplate("cpp.extern", "v")<CR>'
	"
	"===============================================================================================
	"----- Menu : run  ----- --------------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_MenuHeader == 'yes'
		exe "amenu  ".s:Run.'.&Run<Tab>C\/C\+\+       <Nop>'
		exe "amenu  ".s:Run.'.-Sep00-                 <Nop>'
	endif
	"
	exe "amenu  <silent>  ".s:Run.'.save\ and\ &compile<Tab>\<A-F9\>         :call C_Compile()<CR>:redraw<CR>:call C_HlMessage()<CR>'
	exe "amenu  <silent>  ".s:Run.'.&link<Tab>\<F9\>                         :call C_Link()<CR>:redraw<CR>:call C_HlMessage()<CR>'
	exe "amenu  <silent>  ".s:Run.'.&run<Tab>\<C-F9\>                        :call C_Run()<CR>'
	exe "amenu  <silent>  ".s:Run.'.cmd\.\ line\ &arg\.<Tab>\<S-F9\>         :call C_Arguments()<CR>'
	exe "amenu  <silent>  ".s:Run.'.-SEP0-                            :'
	exe "amenu  <silent>  ".s:Run.'.&make                                    :call C_Make()<CR>'
	exe "amenu  <silent>  ".s:Run.'.cmd\.\ line\ ar&g\.\ for\ make           :call C_MakeArguments()<CR>'
	exe "amenu  <silent>  ".s:Run.'.-SEP1-                            :'
	"
	exe "imenu  <silent>  ".s:Run.'.save\ and\ &compile<Tab>\<A-F9\>    <C-C>:call C_Compile()<CR>:redraw<CR>:call C_HlMessage()<CR>'
	exe "imenu  <silent>  ".s:Run.'.&link<Tab>\<F9\>                    <C-C>:call C_Link()<CR>:redraw<CR>:call C_HlMessage()<CR>'
	exe "imenu  <silent>  ".s:Run.'.&run<Tab>\<C-F9\>                   <C-C>:call C_Run()<CR>'
	exe "imenu  <silent>  ".s:Run.'.cmd\.\ line\ &arg\.<Tab>\<S-F9\>    <C-C>:call C_Arguments()<CR>'
	exe "imenu  <silent>  ".s:Run.'.&make                               <C-C>:call C_Make()<CR>'
	exe "imenu  <silent>  ".s:Run.'.cmd\.\ line\ ar&g\.\ for\ make      <C-C>:call C_MakeArguments()<CR>'
	if s:C_SplintIsExecutable==1
		exe "amenu  <silent>  ".s:Run.'.s&plint                                :call C_SplintCheck()<CR>:redraw<CR>:call C_HlMessage()<CR>'
		exe "amenu  <silent>  ".s:Run.'.cmd\.\ line\ arg\.\ for\ spl&int       :call C_SplintArguments()<CR>'
		exe "imenu  <silent>  ".s:Run.'.s&plint                           <C-C>:call C_SplintCheck()<CR>:redraw<CR>:call C_HlMessage()<CR>'
		exe "imenu  <silent>  ".s:Run.'.cmd\.\ line\ arg\.\ for\ spl&int  <C-C>:call C_SplintArguments()<CR>'
		exe "amenu  <silent>  ".s:Run.'.-SEP2-                          :'
	endif
	"
	if s:C_CodeCheckIsExecutable==1
		exe "amenu  <silent>  ".s:Run.'.CodeChec&k                               :call C_CodeCheck()<CR>:redraw<CR>:call C_HlMessage()<CR>'
		exe "amenu  <silent>  ".s:Run.'.cmd\.\ line\ arg\.\ for\ Cod&eCheck      :call C_CodeCheckArguments()<CR>'
		exe "imenu  <silent>  ".s:Run.'.CodeChec&k                          <C-C>:call C_CodeCheck()<CR>:redraw<CR>:call C_HlMessage()<CR>'
		exe "imenu  <silent>  ".s:Run.'.cmd\.\ line\ arg\.\ for\ Cod&eCheck <C-C>:call C_CodeCheckArguments()<CR>'
		exe "amenu  <silent>  ".s:Run.'.-SEP3-                          :'
	endif
	"
	exe "amenu            ".s:Run.'.in&dent                                  :call C_Indent("a")<CR>:redraw<CR>:call C_HlMessage()<CR>'
	exe "imenu            ".s:Run.'.in&dent                             <C-C>:call C_Indent("a")<CR>:redraw<CR>:call C_HlMessage()<CR>'
	exe "vmenu            ".s:Run.'.in&dent                             <C-C>:call C_Indent("v")<CR>:redraw<CR>:call C_HlMessage()<CR>'
	if	s:MSWIN
		exe "amenu  <silent>  ".s:Run.'.&hardcopy\ to\ printer                 :call C_Hardcopy("n")<CR>'
		exe "imenu  <silent>  ".s:Run.'.&hardcopy\ to\ printer            <C-C>:call C_Hardcopy("n")<CR>'
		exe "vmenu  <silent>  ".s:Run.'.&hardcopy\ to\ printer            <C-C>:call C_Hardcopy("v")<CR>'
	else
		exe "amenu  <silent>  ".s:Run.'.&hardcopy\ to\ FILENAME\.ps            :call C_Hardcopy("n")<CR>'
		exe "imenu  <silent>  ".s:Run.'.&hardcopy\ to\ FILENAME\.ps       <C-C>:call C_Hardcopy("n")<CR>'
		exe "vmenu  <silent>  ".s:Run.'.&hardcopy\ to\ FILENAME\.ps       <C-C>:call C_Hardcopy("v")<CR>'
	endif
	exe "imenu  <silent>  ".s:Run.'.-SEP4-                           :'

	exe "amenu  <silent>  ".s:Run.'.&settings                                :call C_Settings()<CR>'
	exe "imenu  <silent>  ".s:Run.'.&settings                           <C-C>:call C_Settings()<CR>'
	exe "imenu  <silent>  ".s:Run.'.-SEP5-                           :'

	if	!s:MSWIN
		exe "amenu  <silent>  ".s:Run.'.&xterm\ size                           :call C_XtermSize()<CR>'
		exe "imenu  <silent>  ".s:Run.'.&xterm\ size                      <C-C>:call C_XtermSize()<CR>'
	endif
	if s:C_OutputGvim == "vim"
		exe "amenu  <silent>  ".s:Run.'.&output:\ VIM->buffer->xterm           :call C_Toggle_Gvim_Xterm()<CR><CR>'
		exe "imenu  <silent>  ".s:Run.'.&output:\ VIM->buffer->xterm      <C-C>:call C_Toggle_Gvim_Xterm()<CR><CR>'
	else
		if s:C_OutputGvim == "buffer"
			exe "amenu  <silent>  ".s:Run.'.&output:\ BUFFER->xterm->vim         :call C_Toggle_Gvim_Xterm()<CR><CR>'
			exe "imenu  <silent>  ".s:Run.'.&output:\ BUFFER->xterm->vim    <C-C>:call C_Toggle_Gvim_Xterm()<CR><CR>'
		else
			exe "amenu  <silent>  ".s:Run.'.&output:\ XTERM->vim->buffer         :call C_Toggle_Gvim_Xterm()<CR><CR>'
			exe "imenu  <silent>  ".s:Run.'.&output:\ XTERM->vim->buffer    <C-C>:call C_Toggle_Gvim_Xterm()<CR><CR>'
		endif
	endif
	"
	"===============================================================================================
	"----- Menu : help  -------------------------------------------------------   {{{2
	"===============================================================================================
	"
	if s:C_Root != ""
		exe " menu  <silent>  ".s:C_Root.'&help\ (C-Support)          :call C_HelpCsupport()<CR>'
		exe "imenu  <silent>  ".s:C_Root.'&help\ (C-Support)     <C-C>:call C_HelpCsupport()<CR>'
		exe " menu  <silent>  ".s:C_Root.'show\ &manual   		       :call C_Help("m")<CR>'
		exe "imenu  <silent>  ".s:C_Root.'show\ &manual 		    <C-C>:call C_Help("m")<CR>'
	endif

endfunction    " ----------  end of function  C_InitMenus  ----------
"
"===============================================================================================
"----- Menu Functions --------------------------------------------------------------------------
"===============================================================================================
"
let s:C_StandardLibs       = [
  \ '&assert\.h' , '&ctype\.h' ,   '&errno\.h' ,
  \ '&float\.h' ,  '&limits\.h' ,  'l&ocale\.h' ,
  \ '&math\.h' ,   'set&jmp\.h' ,  's&ignal\.h' ,
  \ 'stdar&g\.h' , 'st&ddef\.h' ,  '&stdio\.h' ,
  \ 'stdli&b\.h' , 'st&ring\.h' ,  '&time\.h' ,
  \ ]
"
let s:C_C99Libs       = [
  \ '&complex\.h', '&fenv\.h',    '&inttypes\.h',
  \ 'is&o646\.h',  '&stdbool\.h', 's&tdint\.h',
  \ 'tg&math\.h',  '&wchar\.h',   'wct&ype\.h',
  \ ]
"
let s:Cpp_StandardLibs1       = [
  \ '&algorithm', '&bitset',  '&complex',    '&deque',
  \ '&exception', '&fstream', 'f&unctional', 'iomani&p',
  \ '&ios',       'iosf&wd',  'io&stream',   'istrea&m',
  \ 'iterato&r',  '&limits',  'lis&t',       'l&ocale',
  \ ]
"
let s:Cpp_StandardLibs2       = [
  \ '&map',      'memor&y',    '&new',       'numeri&c',
  \ '&ostream',  '&queue',     '&set',       'sst&ream',
  \ 'st&ack',    'stde&xcept', 'stream&buf', 'str&ing',
  \ '&typeinfo', '&utility',   '&valarray',  'v&ector',
  \ ]
"
let s:Cpp_StandardLibs3       = [
  \ 'c&assert', 'c&ctype',  'c&errno',  'c&float',
  \ 'c&limits', 'cl&ocale', 'c&math',   'cset&jmp',
  \ 'cs&ignal', 'cstdar&g', 'cst&ddef', 'c&stdio',
  \ 'cstdli&b', 'cst&ring', 'c&time',
  \ ]

let s:Cpp_IosFlagBits       = [
	\	'ios::&adjustfield', 'ios::bas&efield',           'ios::&boolalpha',
	\	'ios::&dec',         'ios::&fixed',               'ios::floa&tfield',
	\	'ios::&hex',         'ios::&internal',            'ios::&left',
	\	'ios::&oct',         'ios::&right',               'ios::s&cientific',
	\	'ios::sho&wbase',    'ios::showpoint\ \(&1\)',    'ios::show&pos',
	\	'ios::&skipws',      'ios::u&nitbuf',             'ios::&uppercase',
  \ ]

"------------------------------------------------------------------------------
"  C_CIncludeMenus: generate the C/C++-standard library menu entries   {{{1
"------------------------------------------------------------------------------
function! C_CIncludeMenus ( menupath, liblist )
	for item in a:liblist
		let replacement	= substitute( item, '[&\\]*', '','g' )
		exe "anoremenu  ".a:menupath.'.'.item.'          o#include<Tab><'.replacement.'>'
		exe "inoremenu  ".a:menupath.'.'.item.'     <Esc>o#include<Tab><'.replacement.'>'
	endfor
	return
endfunction    " ----------  end of function C_CIncludeMenus  ----------

"------------------------------------------------------------------------------
"  C_CIosFlagMenus: generate the C++ ios flags menu entries   {{{1
"------------------------------------------------------------------------------
function! C_CIosFlagMenus ( menupath, flaglist )
	for item in a:flaglist
		let replacement	= substitute( item, '[^[:alpha:]:]', '','g' )
		exe " noremenu ".a:menupath.'.'.item.'     i'.replacement
		exe "inoremenu ".a:menupath.'.'.item.'      '.replacement
	endfor
	return
endfunction    " ----------  end of function C_CIosFlagMenus  ----------
"
"------------------------------------------------------------------------------
"  C_Input: Input after a highlighted prompt     {{{1
"------------------------------------------------------------------------------
function! C_Input ( promp, text, ... )
	echohl Search																					" highlight prompt
	call inputsave()																			" preserve typeahead
	if a:0 == 0 || a:1 == ''
		let retval	=input( a:promp, a:text )
	else
		let retval	=input( a:promp, a:text, a:1 )
	endif
	call inputrestore()																		" restore typeahead
	echohl None																						" reset highlighting
	let retval  = substitute( retval, '^\s\+', "", "" )		" remove leading whitespaces
	let retval  = substitute( retval, '\s\+$', "", "" )		" remove trailing whitespaces
	return retval
endfunction    " ----------  end of function C_Input ----------
"
"------------------------------------------------------------------------------
"  C_AdjustLineEndComm: adjust line-end comments     {{{1
"------------------------------------------------------------------------------
function! C_AdjustLineEndComm ( mode ) range
	"
	if !exists("b:C_LineEndCommentColumn")
		let	b:C_LineEndCommentColumn	= s:C_LineEndCommColDefault
	endif

	let save_cursor = getpos(".")

	let	save_expandtab	= &expandtab
	exe	":set expandtab"

	if a:mode == 'v'
		let pos0	= line("'<")
		let pos1	= line("'>")
	else
		let pos0	= line(".")
		let pos1	= pos0
	endif

	let	linenumber	= pos0
	exe ":".pos0

	while linenumber <= pos1
		let	line= getline(".")

		if     match( line, '^\s*\/\*.\{-}\*\/' ) == 0
			\ || match( line, '^\s*\/\/.*$' ) == 0
			" comment with leading whitespaces
			let idx1	= 0
			let idx2	= 0
		else
			" look for a C comment
			let idx1	= 1 + match( line, '\s*\/\*.\{-}\*\/' )
			let idx2	= 1 + match( line,    '\/\*.\{-}\*\/' )
			if idx2 == 0
				" look for a C++ comment
				let idx1	= 1 + match( line, '\s*\/\/.*$' )
				let idx2	= 1 + match( line,    '\/\/.*$' )
			endif
		endif

		let	ln	= line(".")
		call setpos(".", [ 0, ln, idx1, 0 ] )
		let vpos1	= virtcol(".")
		call setpos(".", [ 0, ln, idx2, 0 ] )
		let vpos2	= virtcol(".")

		if   ! (   vpos2 == b:C_LineEndCommentColumn
					\	|| vpos1 > b:C_LineEndCommentColumn
					\	|| idx2  == 0 )

			exe ":.,.retab"
			" insert some spaces
			if vpos2 < b:C_LineEndCommentColumn
				let	diff	= b:C_LineEndCommentColumn-vpos2
				call setpos(".", [ 0, ln, vpos2, 0 ] )
				let	@"	= ' '
				exe "normal	".diff."P"
			endif

			" remove some spaces
			if vpos1 < b:C_LineEndCommentColumn && vpos2 > b:C_LineEndCommentColumn
				let	diff	= vpos2 - b:C_LineEndCommentColumn
				call setpos(".", [ 0, ln, b:C_LineEndCommentColumn, 0 ] )
				exe "normal	".diff."x"
			endif

		endif
		let linenumber=linenumber+1
		normal j
	endwhile
	" restore tab expansion settings and cursor position
	let &expandtab	= save_expandtab
	call setpos('.', save_cursor)

endfunction		" ---------- end of function  C_AdjustLineEndComm  ----------
"
"------------------------------------------------------------------------------
"  C_GetLineEndCommCol: get line-end comment position    {{{1
"------------------------------------------------------------------------------
function! C_GetLineEndCommCol ()
	let actcol	= virtcol(".")
	if actcol+1 == virtcol("$")
		let	b:C_LineEndCommentColumn	= ''
		while match( b:C_LineEndCommentColumn, '^\s*\d\+\s*$' ) < 0
			let b:C_LineEndCommentColumn = C_Input( 'start line-end comment at virtual column : ', actcol, '' )
		endwhile
	else
		let	b:C_LineEndCommentColumn	= virtcol(".")
	endif
  echomsg "line end comments will start at column  ".b:C_LineEndCommentColumn
endfunction		" ---------- end of function  C_GetLineEndCommCol  ----------
"
"------------------------------------------------------------------------------
"  C_LineEndComment: single line-end comment    {{{1
"------------------------------------------------------------------------------
function! C_LineEndComment ( )
	if !exists("b:C_LineEndCommentColumn")
		let	b:C_LineEndCommentColumn	= s:C_LineEndCommColDefault
	endif
	" ----- trim whitespaces -----
	exe 's/\s*$//'
	let linelength= virtcol("$") - 1
	if linelength < b:C_LineEndCommentColumn
		let diff	= b:C_LineEndCommentColumn -1 -linelength
		exe "normal	".diff."A "
	endif
	" append at least one blank
	if linelength >= b:C_LineEndCommentColumn
		exe "normal A "
	endif
	call C_InsertTemplate('comment.end-of-line-comment')
endfunction		" ---------- end of function  C_LineEndComment  ----------
"
"------------------------------------------------------------------------------
"  C_MultiLineEndComments: multi line-end comments    {{{1
"------------------------------------------------------------------------------
function! C_MultiLineEndComments ( )
	"
  if !exists("b:C_LineEndCommentColumn")
		let	b:C_LineEndCommentColumn	= s:C_LineEndCommColDefault
  endif
	"
	let pos0	= line("'<")
	let pos1	= line("'>")
	"
	" ----- trim whitespaces -----
  exe pos0.','.pos1.'s/\s*$//'
	"
	" ----- find the longest line -----
	let	maxlength		= 0
	let	linenumber	= pos0
	normal '<
	while linenumber <= pos1
		if  getline(".") !~ "^\\s*$"  && maxlength<virtcol("$")
			let maxlength= virtcol("$")
		endif
		let linenumber=linenumber+1
		normal j
	endwhile
	"
	if maxlength < b:C_LineEndCommentColumn
	  let maxlength = b:C_LineEndCommentColumn
	else
	  let maxlength = maxlength+1		" at least 1 blank
	endif
	"
	" ----- fill lines with blanks -----
	let	linenumber	= pos0
	while linenumber <= pos1
		exe ":".linenumber
		if getline(".") !~ "^\\s*$"
			let diff	= maxlength - virtcol("$")
			exe "normal	".diff."A "
			call C_InsertTemplate('comment.end-of-line-comment')
		endif
		let linenumber=linenumber+1
	endwhile
	"
	" ----- back to the begin of the marked block -----
	let diff	= pos1-pos0
	normal a
	if pos1-pos0 > 0
		exe "normal ".diff."k"
	endif
endfunction		" ---------- end of function  C_MultiLineEndComments  ----------
"
"------------------------------------------------------------------------------
"  C_Comment_C_SectionAll: Section Comments    {{{1
"------------------------------------------------------------------------------
"
function! C_Comment_C_SectionAll ( type )

	call C_InsertTemplate("comment.file-section-cpp-header-includes")
	call C_InsertTemplate("comment.file-section-cpp-macros")
	call C_InsertTemplate("comment.file-section-cpp-typedefs")
	call C_InsertTemplate("comment.file-section-cpp-data-types")
	if a:type=="cpp"
		call C_InsertTemplate("comment.file-section-cpp-class-defs")
	endif
	call C_InsertTemplate("comment.file-section-cpp-local-variables")
	call C_InsertTemplate("comment.file-section-cpp-prototypes")
	call C_InsertTemplate("comment.file-section-cpp-function-defs-exported")
	call C_InsertTemplate("comment.file-section-cpp-function-defs-local")
	if a:type=="cpp"
		call C_InsertTemplate("comment.file-section-cpp-class-implementations-exported")
		call C_InsertTemplate("comment.file-section-cpp-class-implementations-local")
	endif

endfunction    " ----------  end of function C_Comment_C_SectionAll ----------
"
function! C_Comment_H_SectionAll ( type )

	call C_InsertTemplate("comment.file-section-hpp-header-includes")
	call C_InsertTemplate("comment.file-section-hpp-macros")
	call C_InsertTemplate("comment.file-section-hpp-exported-typedefs")
	call C_InsertTemplate("comment.file-section-hpp-exported-data-types")
	if a:type=="cpp"
		call C_InsertTemplate("comment.file-section-hpp-exported-class-defs")
	endif
	call C_InsertTemplate("comment.file-section-hpp-exported-variables")
	call C_InsertTemplate("comment.file-section-hpp-exported-function-declarations")

endfunction    " ----------  end of function C_Comment_H_SectionAll ----------
"
"----------------------------------------------------------------------
"  C_CodeComment : Code -> Comment   {{{1
"----------------------------------------------------------------------
function! C_CodeComment( mode, style )

	if a:mode=="a"
		if a:style == 'yes'
			silent exe ":s#^#/\* #"
			silent put = ' */'
		else
			silent exe ":s#^#//#"
		endif
	endif

	if a:mode=="v"
		if a:style == 'yes'
			silent exe ":'<,'>s/^/ \* /"
			silent exe ":'< s'^ '\/'"
			silent exe ":'>"
			silent put = ' */'
		else
			silent exe ":'<,'>s#^#//#"
		endif
	endif

endfunction    " ----------  end of function  C_CodeComment  ----------
"
"----------------------------------------------------------------------
"  C_StartMultilineComment : Comment -> Code   {{{1
"----------------------------------------------------------------------
let s:C_StartMultilineComment	= '^\s*\/\*[\*! ]\='

function! C_RemoveCComment( start, end )

	if a:end-a:start<1
		return 0										" lines removed
	endif
	"
	" Is the C-comment complete ? Get length.
	"
	let check				= getline(	a:start ) =~ s:C_StartMultilineComment
	let	linenumber	= a:start+1
	while linenumber < a:end && getline(	linenumber ) !~ '^\s*\*\/'
		let check				= check && getline(	linenumber ) =~ '^\s*\*[ ]\='
		let linenumber	= linenumber+1
	endwhile
	let check = check && getline(	linenumber ) =~ '^\s*\*\/'
	"
	" remove a complete comment
	"
	if check
		exe "silent :".a:start.'   s/'.s:C_StartMultilineComment.'//'
		let	linenumber1	= a:start+1
		while linenumber1 < linenumber
			exe "silent :".linenumber1.' s/^\s*\*[ ]\=//'
			let linenumber1	= linenumber1+1
		endwhile
		exe "silent :".linenumber1.'   s/^\s*\*\///'
	endif

	return linenumber-a:start+1			" lines removed
endfunction    " ----------  end of function  C_RemoveCComment  ----------
"
"----------------------------------------------------------------------
"  C_CommentCode : Comment -> Code       {{{1
"----------------------------------------------------------------------
function! C_CommentCode(mode)
	if a:mode=="a"
		let	pos1		= line(".")
		let	pos2		= pos1
	endif
	if a:mode=="v"
		let	pos1		= line("'<")
		let	pos2		= line("'>")
	endif

	let	removed	= 0
	"
	let	linenumber=pos1
	while linenumber <= pos2
		" Do we have a C++ comment ?
		if getline(	linenumber ) =~ '^\s*//'
			exe "silent :".linenumber.' s#^\s*//##'
			let	removed    = 1
		endif
		" Do we have a C   comment ?
		if removed == 0 && getline(	linenumber ) =~ s:C_StartMultilineComment
			let removed = C_RemoveCComment(linenumber,pos2)
		endif

		if removed!=0
			let linenumber = linenumber+removed
			let	removed    = 0
		else
			let linenumber = linenumber+1
		endif
	endwhile
endfunction    " ----------  end of function  C_CommentCode  ----------
"
"----------------------------------------------------------------------
"  C_CommentCppToC : C++ Comment -> C Comment       {{{1
"  Removes trailing whitespaces.
"----------------------------------------------------------------------
function! C_CommentCppToC()
		silent! exe ':s#\/\/\s*\(.*\)\s*$#/* \1 */#'
endfunction    " ----------  end of function  C_CommentCppToC  ----------
"
"----------------------------------------------------------------------
"  C_CommentCToCpp : C Comment -> C++ Comment       {{{1
"  Changes the first comment in case of multiple comments:
"    xxxx;               /*  */ /*  */
"    xxxx;               //  /*  */
"  Removes trailing whitespaces.
"----------------------------------------------------------------------
function! C_CommentCToCpp()
		silent! exe ':s!\/\*\s*\(.\{-}\)\*\/!\/\/ \1!'
		silent! exe ':s!\s*$!!'
endfunction    " ----------  end of function  C_CommentCToCpp  ----------
"
"=====================================================================================
"----- Menu : Statements -----------------------------------------------------------
"=====================================================================================
"
"------------------------------------------------------------------------------
"  C_PPIf0 : #if 0 .. #endif        {{{1
"------------------------------------------------------------------------------
function! C_PPIf0 (mode)
	"
	let	s:C_If0_Counter	= 0
	let	save_line					= line(".")
	let	actual_line				= 0
	"
	" search for the maximum option number (if any)
	"
	normal gg
	while actual_line < search( s:C_If0_Txt."\\d\\+" )
		let actual_line	= line(".")
	 	let actual_opt  = matchstr( getline(actual_line), s:C_If0_Txt."\\d\\+" )
		let actual_opt  = strpart( actual_opt, strlen(s:C_If0_Txt),strlen(actual_opt)-strlen(s:C_If0_Txt))
		if s:C_If0_Counter < actual_opt
			let	s:C_If0_Counter = actual_opt
		endif
	endwhile
	let	s:C_If0_Counter = s:C_If0_Counter+1
	silent exe ":".save_line
	"
	if a:mode=='a'
		let zz=    "\n#if  0     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n"
		let zz= zz."\n#endif     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n\n"
		put =zz
		normal 4k
	endif

	if a:mode=='v'
		let	pos1	= line("'<")
		let	pos2	= line("'>")
		let zz=      "#endif     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n\n"
		exe ":".pos2."put =zz"
		let zz=    "\n#if  0     ".s:C_Com1." ----- #if 0 : ".s:C_If0_Txt.s:C_If0_Counter." ----- ".s:C_Com2."\n"
		exe ":".pos1."put! =zz"
		"
		if  &foldenable && foldclosed(".")
			normal zv
		endif
	endif

endfunction    " ----------  end of function C_PPIf0 ----------
"
"------------------------------------------------------------------------------
"  C_PPIf0Remove : remove  #if 0 .. #endif        {{{1
"------------------------------------------------------------------------------
function! C_PPIf0Remove ()
	"
	" cursor on fold: open fold first
	if  &foldenable && foldclosed(".")
		normal zv
	endif
	"
	let frstline	= searchpair( '^\s*#if\s\+0', '', '^\s*#endif\>.\+\<If0Label_', 'bn' )
  if frstline<=0
		echohl WarningMsg | echo 'no  #if 0 ... #endif  found or cursor not inside such a directive'| echohl None
    return
  endif
	let lastline	= searchpair( '^\s*#if\s\+0', '', '^\s*#endif\>.\+\<If0Label_', 'n' )
	if lastline<=0
		echohl WarningMsg | echo 'no  #if 0 ... #endif  found or cursor not inside such a directive'| echohl None
		return
	endif
  let actualnumber1  = matchstr( getline(frstline), s:C_If0_Txt."\\d\\+" )
  let actualnumber2  = matchstr( getline(lastline), s:C_If0_Txt."\\d\\+" )
	if actualnumber1 != actualnumber2
    echohl WarningMsg | echo 'lines '.frstline.', '.lastline.': comment tags do not match'| echohl None
		return
	endif

  silent exe ':'.lastline.','.lastline.'d'
	silent exe ':'.frstline.','.frstline.'d'

endfunction    " ----------  end of function C_PPIf0Remove ----------
"
"-------------------------------------------------------------------------------
"   C_LegalizeName : replace non-word characters by underscores
"   - multiple whitespaces
"   - multiple non-word characters
"   - multiple underscores
"-------------------------------------------------------------------------------
function! C_LegalizeName ( name )
	let identifier = substitute(     a:name, '\s\+',  '_', 'g' )
	let identifier = substitute( identifier, '\W\+',  '_', 'g' )
	let identifier = substitute( identifier, '_\+', '_', 'g' )
	return identifier
endfunction    " ----------  end of function C_LegalizeName  ----------

"------------------------------------------------------------------------------
"  C_CodeSnippet : read / edit code snippet       {{{1
"------------------------------------------------------------------------------
function! C_CodeSnippet(mode)

	if isdirectory(s:C_CodeSnippets)
		"
		" read snippet file, put content below current line and indent
		"
		if a:mode == "r"
			if has("browse")
				let	l:snippetfile=browse(0,"read a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("read snippet ", s:C_CodeSnippets, "file" )
			endif
			if filereadable(l:snippetfile)
				let	linesread= line("$")
				let l:old_cpoptions	= &cpoptions " Prevent the alternate buffer from being set to this files
				setlocal cpoptions-=a
				:execute "read ".l:snippetfile
				let &cpoptions	= l:old_cpoptions		" restore previous options
				let	linesread= line("$")-linesread-1
				if linesread>=0 && match( l:snippetfile, '\.\(ni\|noindent\)$' ) < 0
				endif
			endif
			if line(".")==2 && getline(1)=~"^$"
				silent exe ":1,1d"
			endif
		endif
		"
		" update current buffer / split window / edit snippet file
		"
		if a:mode == "e"
			if has("browse")
				let	l:snippetfile	= browse(0,"edit a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("edit snippet ", s:C_CodeSnippets, "file" )
			endif
			if l:snippetfile != ""
				:execute "update! | split | edit ".l:snippetfile
			endif
		endif
		"
		" write whole buffer into snippet file
		"
		if a:mode == "w" || a:mode == "wv"
			if has("browse")
				let	l:snippetfile	= browse(0,"edit a code snippet",s:C_CodeSnippets,"")
			else
				let	l:snippetfile=input("edit snippet ", s:C_CodeSnippets, "file" )
			endif
			if l:snippetfile != ""
				if filereadable(l:snippetfile)
					if confirm("File ".l:snippetfile." exists ! Overwrite ? ", "&Cancel\n&No\n&Yes") != 3
						return
					endif
				endif
				if a:mode == "w"
					:execute ":write! ".l:snippetfile
				else
					:execute ":*write! ".l:snippetfile
				endif
			endif
		endif

	else
		echo "code snippet directory ".s:C_CodeSnippets." does not exist (please create it)"
	endif
endfunction    " ----------  end of function C_CodeSnippets  ----------
"
"------------------------------------------------------------------------------
"  C_help : builtin completion    {{{1
"------------------------------------------------------------------------------
function!	C_ForTypeComplete ( ArgLead, CmdLine, CursorPos )
	"
	" show all types
	if a:ArgLead == ''
		return s:C_ForTypes
	endif
	"
	" show types beginning with a:ArgLead
	let	expansions	= []
	for item in s:C_ForTypes
		if match( item, '\<'.a:ArgLead.'\w*' ) == 0
			call add( expansions, item )
		endif
	endfor
	return	expansions
endfunction    " ----------  end of function C_ForTypeComplete  ----------
"
"------------------------------------------------------------------------------
"  C_CodeFor : for (idiom)       {{{1
"------------------------------------------------------------------------------
function! C_CodeFor( direction, mode )
	"
	if a:direction == 'up'
		let	string	= 'INCR.'
	else
		let	string	= 'DECR.'
	endif
	let	string	= C_Input( '[TYPE (expand)] VARIABLE [START [END ['.string.']]] : ', '', 'customlist,C_ForTypeComplete' )
	if string == ''
		return
	endif
	"
	let part		= ['']
	let nextindex	= -1
	for item in s:C_ForTypes
		let nextindex	= matchend( string, '^'.item )
		if nextindex >= 0
			let part[0]	= item
			let	string	= strpart( string, nextindex-1 )
		endif
	endfor
	let part	= part + split( string )

	if len( part ) 	> 5
    echohl WarningMsg | echomsg "for loop construction : to many arguments " | echohl None
		return
	endif

	let missing	= 0
	while len(part) < 5
		let part	= part + ['']
		let missing	= missing+1
	endwhile

	let [ loopvar_type, loopvar, startval, endval, incval ]	= part

	if incval==''
		let incval	= '1'
	endif

	if a:direction == 'up'
		if endval == ''
			let endval	= 'n'
		endif
		if startval == ''
			let startval	= '0'
		endif
		let zz= 'for ( '.loopvar_type.loopvar.' = '.startval.'; '.loopvar.' < '.endval.'; '.loopvar.' += '.incval.' )'
	else
		if endval == ''
			let endval	= '0'
		endif
		if startval == ''
			let startval	= 'n-1'
		endif
		let zz= 'for ( '.loopvar_type.loopvar.' = '.startval.'; '.loopvar.' >= '.endval.'; '.loopvar.' -= '.incval.' )'
	endif
	"
	" use internal formatting to avoid conficts when using == below
	let	equalprg_save	= &equalprg
	set equalprg=

	" ----- normal mode ----------------
	if a:mode=='a'
		put =zz
		normal 2==
	endif
	" ----- visual mode ----------------
	if a:mode=='v'
		let	pos1	= line("'<")
		let	pos2	= line("'>")
		let	zz	= zz.' {'
		let zz2=    '}'
		exe ":".pos2."put =zz2"
		exe ":".pos1."put! =zz"
		:exe 'normal ='.(pos2-pos1+2).'+'
	endif
	"
	" restore formatter programm
	let &equalprg	= equalprg_save
	"
	" position the cursor
	"
	normal ^
	if missing == 1
		let match	= search( '\<'.incval.'\>' )
	else
		if missing == 2
			let match	= search( '\<'.endval.'\>' )
		else
			if missing == 3
				let match	= search( '\<'.startval.'\>' )
			endif
		endif
	endif
	"
endfunction    " ----------  end of function C_CodeFor ----------
"
"------------------------------------------------------------------------------
"  Handle prototypes       {{{1
"------------------------------------------------------------------------------
"
let s:C_Prototype        = []
let s:C_PrototypeShow    = []
let s:C_PrototypeCounter = 0
let s:C_CComment         = '\/\*.\{-}\*\/\s*'		" C comment with trailing whitespaces
																								"  '.\{-}'  any character, non-greedy
let s:C_CppComment       = '\/\/.*$'						" C++ comment
"
"------------------------------------------------------------------------------
"  C_ProtoPick : pick up (normal/visual)       {{{1
"------------------------------------------------------------------------------
function! C_ProtoPick (mode)
	if a:mode=="n"
		" --- normal mode -------------------
		let	pos1	= line(".")
		let	pos2	= pos1
	else
		" --- visual mode -------------------
		let	pos1	= line("'<")
		let	pos2	= line("'>")
	endif
	"
	" remove C/C++-comments, leading and trailing whitespaces, squeeze whitespaces
	"
	let prototyp   = ''
	let	linenumber = pos1
	while linenumber <= pos2
		let newline			= getline(linenumber)
		let newline 	  = substitute( newline, s:C_CppComment, "", "" ) " remove C++ comment
		let prototyp		= prototyp." ".newline
		let linenumber	= linenumber+1
	endwhile
	"
	let prototyp  = substitute( prototyp, '^\s\+', "", "" )					" remove leading whitespaces
	let prototyp  = substitute( prototyp, s:C_CComment, "", "g" )		" remove (multiline) C comments
	let prototyp  = substitute( prototyp, '\s\+', " ", "g" )				" squeeze whitespaces
	let prototyp  = substitute( prototyp, '\s\+$', "", "" )					" remove trailing whitespaces
	"
	" remove template keyword
	"
	let prototyp  = substitute( prototyp, '^template\s*<\s*class \w\+\s*>\s*', "", "" )
	"
	let parlist 	= stridx( prototyp, '(' )													" start of the parameter list
	let part1   	= strpart( prototyp, 0, parlist )
	let part2   	= strpart( prototyp, parlist )
	"
	" remove the scope res. operator
	"
	let part1		  = substitute( part1, '<\s*\w\+\s*>', "", "g" )
	let part1   	= substitute( part1, '\<std\s*::', 'std##', 'g' )	" remove the scope res. operator
	let part1   	= substitute( part1, '\<\h\w*\s*::', '', 'g' )		" remove the scope res. operator
	let part1   	= substitute( part1, '\<std##', 'std::', 'g' )		" remove the scope res. operator
	let	prototyp	= part1.part2
	"
	" remove trailing parts of the function body; add semicolon
	"
	let prototyp	= substitute( prototyp, '\s*{.*$', "", "" )
	let prototyp	= prototyp.";\n"
	"
	" bookkeeping
	"
	let s:C_PrototypeCounter += 1
	let s:C_Prototype        += [prototyp]
	let s:C_PrototypeShow    += ["(".s:C_PrototypeCounter.") ".bufname("%")." #  ".prototyp]
	"
	echon	s:C_PrototypeCounter.' prototype'
	if s:C_PrototypeCounter > 1
		echon	's'
	endif
	"
endfunction    " ---------  end of function C_ProtoPick  ----------
"
"------------------------------------------------------------------------------
"  C_ProtoInsert : insert       {{{1
"------------------------------------------------------------------------------
function! C_ProtoInsert ()
	"
	" use internal formatting to avoid conficts when using == below
	let	equalprg_save	= &equalprg
	set equalprg=
	"
	if s:C_PrototypeCounter > 0
		for protytype in s:C_Prototype
			put =protytype
		endfor
		let	lines	= s:C_PrototypeCounter	- 1
		silent exe "normal =".lines."-"
		call C_ProtoClear()
	else
		echo "currently no prototypes available"
	endif
	"
	" restore formatter programm
	let &equalprg	= equalprg_save
	"
endfunction    " ---------  end of function C_ProtoInsert  ----------
"
"------------------------------------------------------------------------------
"  C_ProtoClear : clear       {{{1
"------------------------------------------------------------------------------
function! C_ProtoClear ()
	if s:C_PrototypeCounter > 0
		let s:C_Prototype        = []
		let s:C_PrototypeShow    = []
		if s:C_PrototypeCounter == 1
			echo	s:C_PrototypeCounter.' prototype deleted'
		else
			echo	s:C_PrototypeCounter.' prototypes deleted'
		endif
		let s:C_PrototypeCounter = 0
	else
		echo "currently no prototypes available"
	endif
endfunction    " ---------  end of function C_ProtoClear  ----------
"
"------------------------------------------------------------------------------
"  C_ProtoShow : show       {{{1
"------------------------------------------------------------------------------
function! C_ProtoShow ()
	if s:C_PrototypeCounter > 0
		for protytype in s:C_PrototypeShow
			echo protytype
		endfor
	else
		echo "currently no prototypes available"
	endif
endfunction    " ---------  end of function C_ProtoShow  ----------
"
"------------------------------------------------------------------------------
"  C_EscapeBlanks : C_EscapeBlanks       {{{1
"------------------------------------------------------------------------------
function! C_EscapeBlanks (arg)
	return  substitute( a:arg, " ", "\\ ", "g" )
endfunction    " ---------  end of function C_EscapeBlanks  ----------
"
"------------------------------------------------------------------------------
"  C_Compile : C_Compile       {{{1
"------------------------------------------------------------------------------
"  The standard make program 'make' called by vim is set to the C or C++ compiler
"  and reset after the compilation  (setlocal makeprg=... ).
"  The errorfile created by the compiler will now be read by gvim and
"  the commands cl, cp, cn, ... can be used.
"------------------------------------------------------------------------------
function! C_Compile ()

	let	l:currentbuffer	= bufname("%")
	let s:C_HlMessage = ""
	exe	":cclose"
	let	Sou		= expand("%:p")											" name of the file in the current buffer
	let	Obj		= expand("%:p:r").s:C_ObjExtension	" name of the object
	let SouEsc= escape( Sou, s:escfilename )
	let ObjEsc= escape( Obj, s:escfilename )

	" update : write source file if necessary
	exe	":update"

	" compilation if object does not exist or object exists and is older then the source
	if !filereadable(Obj) || (filereadable(Obj) && (getftime(Obj) < getftime(Sou)))
		" &makeprg can be a string containing blanks
		let makeprg_saved='"'.&makeprg.'"'
		if expand("%:e") == s:C_CExtension
			exe		"setlocal makeprg=".s:C_CCompiler
		else
			exe		"setlocal makeprg=".s:C_CplusCompiler
		endif
		"
		" COMPILATION
		"
		if s:MSWIN
			exe		"make ".s:C_CFlags." \"".SouEsc."\" -o \"".ObjEsc."\""
		else
			exe		"make ".s:C_CFlags." ".SouEsc." -o ".ObjEsc
		endif
		exe	"setlocal makeprg=".makeprg_saved
		"
		" open error window if necessary
		:redraw!
		exe	":botright cwindow"
	else
		let s:C_HlMessage = " '".Obj."' is up to date "
	endif

endfunction    " ----------  end of function C_Compile ----------
"
"------------------------------------------------------------------------------
"  C_Link : C_Link       {{{1
"------------------------------------------------------------------------------
"  The standard make program which is used by gvim is set to the compiler
"  (for linking) and reset after linking.
"
"  calls: C_Compile
"------------------------------------------------------------------------------
function! C_Link ()

	call	C_Compile()

	let s:C_HlMessage = ""
	let	Sou		= expand("%:p")						       		" name of the file in the current buffer
	let	Obj		= expand("%:p:r").s:C_ObjExtension	" name of the object file
	let	Exe		= expand("%:p:r").s:C_ExeExtension	" name of the executable
	let ObjEsc= escape( Obj, s:escfilename )
	let ExeEsc= escape( Exe, s:escfilename )

	" no linkage if:
	"   executable exists
	"   object exists
	"   source exists
	"   executable newer then object
	"   object newer then source

	if    filereadable(Exe)                &&
      \ filereadable(Obj)                &&
      \ filereadable(Sou)                &&
      \ (getftime(Exe) >= getftime(Obj)) &&
      \ (getftime(Obj) >= getftime(Sou))
		let s:C_HlMessage = " '".Exe."' is up to date "
		return
	endif

	" linkage if:
	"   object exists
	"   source exists
	"   object newer then source

	if filereadable(Obj) && (getftime(Obj) >= getftime(Sou))
		let makeprg_saved='"'.&makeprg.'"'
		if expand("%:e") == s:C_CExtension
			exe		"setlocal makeprg=".s:C_CCompiler
		else
			exe		"setlocal makeprg=".s:C_CplusCompiler
		endif
		let v:statusmsg=""
		if s:MSWIN
			silent exe "make ".s:C_LFlags." ".s:C_Libs." -o \"".ExeEsc."\" \"".ObjEsc."\""
		else
			silent exe "make ".s:C_LFlags." ".s:C_Libs." -o ".ExeEsc." ".ObjEsc
		endif
		if v:statusmsg != ""
			let s:C_HlMessage = v:statusmsg
		endif
		exe	"setlocal makeprg=".makeprg_saved
	endif
endfunction    " ----------  end of function C_Link ----------
"
"------------------------------------------------------------------------------
"  C_Run : 	C_Run       {{{1
"  calls: C_Link
"------------------------------------------------------------------------------
"
let s:C_OutputBufferName   = "C-Output"
let s:C_OutputBufferNumber = -1
"
function! C_Run ()
"
	let Sou  		= expand("%:p")														" name of the source file
	let Obj  		= expand("%:p:r").s:C_ObjExtension				" name of the object file
	let Exe  		= expand("%:p:r").s:C_ExeExtension				" name of the executable
	let ExeEsc  = escape( Exe, s:escfilename )						" name of the executable, escaped
	"
	let l:arguments     = exists("b:C_CmdLineArgs") ? b:C_CmdLineArgs : ''
	"
	let	l:currentbuffer	= bufname("%")
	"
	"==============================================================================
	"  run : run from the vim command line
	"==============================================================================
	if s:C_OutputGvim == "vim"
		"
		silent call C_Link()
		"
		if	executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
			if s:MSWIN
				exe		"!\"".ExeEsc."\" ".l:arguments
			else
				exe		"!".ExeEsc." ".l:arguments
			endif
		else
			echomsg "file ".Exe." does not exist / is not executable"
		endif

	endif
	"
	"==============================================================================
	"  run : redirect output to an output buffer
	"==============================================================================
	if s:C_OutputGvim == "buffer"
		let	l:currentbuffernr	= bufnr("%")
		"
		silent call C_Link()
		"
		if l:currentbuffer ==  bufname("%")
			"
			"
			if bufloaded(s:C_OutputBufferName) != 0 && bufwinnr(s:C_OutputBufferNumber)!=-1
				exe bufwinnr(s:C_OutputBufferNumber) . "wincmd w"
				" buffer number may have changed, e.g. after a 'save as'
				if bufnr("%") != s:C_OutputBufferNumber
					let s:C_OutputBufferNumber	= bufnr(s:C_OutputBufferName)
					exe ":bn ".s:C_OutputBufferNumber
				endif
			else
				silent exe ":new ".s:C_OutputBufferName
				let s:C_OutputBufferNumber=bufnr("%")
				setlocal buftype=nofile
				setlocal noswapfile
				setlocal syntax=none
				setlocal bufhidden=delete
				setlocal tabstop=8
			endif
			"
			" run programm
			"
			setlocal	modifiable
			if	executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
				if s:MSWIN
					exe		"%!\"".ExeEsc."\" ".l:arguments
				else
					exe		"%!".ExeEsc." ".l:arguments
				endif
			endif
			setlocal	nomodifiable
			"
			if winheight(winnr()) >= line("$")
				exe bufwinnr(l:currentbuffernr) . "wincmd w"
			endif
			"
		endif
	endif
	"
	"==============================================================================
	"  run : run in a detached xterm  (not available for MS Windows)
	"==============================================================================
	if s:C_OutputGvim == "xterm"
		"
		silent call C_Link()
		"
		if	executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
			if s:MSWIN
				exe		"!\"".ExeEsc."\" ".l:arguments
			else
				silent exe '!xterm -title '.ExeEsc.' '.s:C_XtermDefaults.' -e '.s:C_Wrapper.' '.ExeEsc.' '.l:arguments.' &'
				:redraw!
			endif
		endif
	endif

endfunction    " ----------  end of function C_Run ----------
"
"------------------------------------------------------------------------------
"  C_Arguments : Arguments for the executable       {{{1
"------------------------------------------------------------------------------
function! C_Arguments ()
	let	Exe		  = expand("%:r").s:C_ExeExtension
  if Exe == ""
		redraw
		echohl WarningMsg | echo "no file name " | echohl None
		return
  endif
	let	prompt	= 'command line arguments for "'.Exe.'" : '
	if exists("b:C_CmdLineArgs")
		let	b:C_CmdLineArgs= C_Input( prompt, b:C_CmdLineArgs, 'file' )
	else
		let	b:C_CmdLineArgs= C_Input( prompt , "", 'file' )
	endif
endfunction    " ----------  end of function C_Arguments ----------
"
"----------------------------------------------------------------------
"  C_Toggle_Gvim_Xterm : change output destination       {{{1
"----------------------------------------------------------------------
function! C_Toggle_Gvim_Xterm ()

	if s:C_OutputGvim == "vim"
		if has("gui_running")
			exe "aunmenu  <silent>  ".s:Run.'.&output:\ VIM->buffer->xterm'
			exe "amenu    <silent>  ".s:Run.'.&output:\ BUFFER->xterm->vim              :call C_Toggle_Gvim_Xterm()<CR><CR>'
			exe "imenu    <silent>  ".s:Run.'.&output:\ BUFFER->xterm->vim         <C-C>:call C_Toggle_Gvim_Xterm()<CR><CR>'
		endif
		let	s:C_OutputGvim	= "buffer"
	else
		if s:C_OutputGvim == "buffer"
			if has("gui_running")
				exe "aunmenu  <silent>  ".s:Run.'.&output:\ BUFFER->xterm->vim'
				if (!s:MSWIN)
					exe "amenu    <silent>  ".s:Run.'.&output:\ XTERM->vim->buffer            :call C_Toggle_Gvim_Xterm()<CR><CR>'
					exe "imenu    <silent>  ".s:Run.'.&output:\ XTERM->vim->buffer       <C-C>:call C_Toggle_Gvim_Xterm()<CR><CR>'
				else
					exe "amenu    <silent>  ".s:Run.'.&output:\ VIM->buffer->xterm            :call C_Toggle_Gvim_Xterm()<CR><CR>'
					exe "imenu    <silent>  ".s:Run.'.&output:\ VIM->buffer->xterm       <C-C>:call C_Toggle_Gvim_Xterm()<CR><CR>'
				endif
			endif
			if (!s:MSWIN) && (s:C_Display != '')
				let	s:C_OutputGvim	= "xterm"
			else
				let	s:C_OutputGvim	= "vim"
			endif
		else
			" ---------- output : xterm -> gvim
			if has("gui_running")
				exe "aunmenu  <silent>  ".s:Run.'.&output:\ XTERM->vim->buffer'
				exe "amenu    <silent>  ".s:Run.'.&output:\ VIM->buffer->xterm            :call C_Toggle_Gvim_Xterm()<CR><CR>'
				exe "imenu    <silent>  ".s:Run.'.&output:\ VIM->buffer->xterm       <C-C>:call C_Toggle_Gvim_Xterm()<CR><CR>'
			endif
			let	s:C_OutputGvim	= "vim"
		endif
	endif
	echomsg "output destination is '".s:C_OutputGvim."'"

endfunction    " ----------  end of function C_Toggle_Gvim_Xterm ----------
"
"------------------------------------------------------------------------------
"  C_XtermSize : xterm geometry       {{{1
"------------------------------------------------------------------------------
function! C_XtermSize ()
	let regex	= '-geometry\s\+\d\+x\d\+'
	let geom	= matchstr( s:C_XtermDefaults, regex )
	let geom	= matchstr( geom, '\d\+x\d\+' )
	let geom	= substitute( geom, 'x', ' ', "" )
	let	answer= C_Input("   xterm size (COLUMNS LINES) : ", geom )
	while match(answer, '^\s*\d\+\s\+\d\+\s*$' ) < 0
		let	answer= C_Input(" + xterm size (COLUMNS LINES) : ", geom )
	endwhile
	let answer  = substitute( answer, '\s\+', "x", "" )						" replace inner whitespaces
	let s:C_XtermDefaults	= substitute( s:C_XtermDefaults, regex, "-geometry ".answer , "" )
endfunction    " ----------  end of function C_XtermSize ----------
"
"------------------------------------------------------------------------------
"  C_MakeArguments : run make(1)       {{{1
"------------------------------------------------------------------------------

let s:C_MakeCmdLineArgs   = ""     " command line arguments for Run-make; initially empty

function! C_MakeArguments ()
	let	s:C_MakeCmdLineArgs= C_Input("make command line arguments : ",s:C_MakeCmdLineArgs )
endfunction    " ----------  end of function C_MakeArguments ----------
"
function! C_Make()
	" update : write source file if necessary
	exe	":update"
	" run make
	exe		":!make ".s:C_MakeCmdLineArgs
endfunction    " ----------  end of function C_Make ----------
"
"------------------------------------------------------------------------------
"  C_SplintArguments : splint command line arguments       {{{1
"------------------------------------------------------------------------------
function! C_SplintArguments ()
	if s:C_SplintIsExecutable==0
		let s:C_HlMessage = ' Splint is not executable or not installed! '
	else
		let	prompt	= 'Splint command line arguments for "'.expand("%").'" : '
		if exists("b:C_SplintCmdLineArgs")
			let	b:C_SplintCmdLineArgs= C_Input( prompt, b:C_SplintCmdLineArgs )
		else
			let	b:C_SplintCmdLineArgs= C_Input( prompt , "" )
		endif
	endif
endfunction    " ----------  end of function C_SplintArguments ----------
"
"------------------------------------------------------------------------------
"  C_SplintCheck : run splint(1)        {{{1
"------------------------------------------------------------------------------
function! C_SplintCheck ()
	if s:C_SplintIsExecutable==0
		let s:C_HlMessage = ' Splint is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage = ""
	exe	":cclose"
	silent exe	":update"
	let makeprg_saved='"'.&makeprg.'"'
	" Windows seems to need this:
	if	s:MSWIN
		:compiler splint
	endif
	:setlocal makeprg=splint
	"
	let l:arguments  = exists("b:C_SplintCmdLineArgs") ? b:C_SplintCmdLineArgs : ' '
	silent exe	"make ".l:arguments." ".escape(l:currentbuffer,s:escfilename)
	exe	"setlocal makeprg=".makeprg_saved
	exe	":botright cwindow"
	"
	" message in case of success
	"
	if l:currentbuffer == bufname("%")
		let s:C_HlMessage = " Splint --- no warnings for : ".l:currentbuffer
	endif
endfunction    " ----------  end of function C_SplintCheck ----------
"
"------------------------------------------------------------------------------
"  C_CodeCheckArguments : CodeCheck command line arguments       {{{1
"------------------------------------------------------------------------------
function! C_CodeCheckArguments ()
	if s:C_CodeCheckIsExecutable==0
		let s:C_HlMessage = ' CodeCheck is not executable or not installed! '
	else
		let	prompt	= 'CodeCheck command line arguments for "'.expand("%").'" : '
		if exists("b:C_CodeCheckCmdLineArgs")
			let	b:C_CodeCheckCmdLineArgs= C_Input( prompt, b:C_CodeCheckCmdLineArgs )
		else
			let	b:C_CodeCheckCmdLineArgs= C_Input( prompt , s:C_CodeCheckOptions )
		endif
	endif
endfunction    " ----------  end of function C_CodeCheckArguments ----------
"
"------------------------------------------------------------------------------
"  C_CodeCheck : run CodeCheck       {{{1
"------------------------------------------------------------------------------
function! C_CodeCheck ()
	if s:C_CodeCheckIsExecutable==0
		let s:C_HlMessage = ' CodeCheck is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage = ""
	exe	":cclose"
	silent exe	":update"
	let makeprg_saved='"'.&makeprg.'"'
	exe	"setlocal makeprg=".s:C_CodeCheckExeName
	"
	" match the splint error messages (quickfix commands)
	" ignore any lines that didn't match one of the patterns
	"
	:setlocal errorformat=%f(%l)%m
	"
	let l:arguments  = exists("b:C_CodeCheckCmdLineArgs") ? b:C_CodeCheckCmdLineArgs : ""
	if l:arguments == ""
		let l:arguments	=	s:C_CodeCheckOptions
	endif
	exe	":make ".l:arguments." ".escape( l:currentbuffer, s:escfilename )
	exe	':setlocal errorformat='
	exe	":setlocal makeprg=".makeprg_saved
	exe	":botright cwindow"
	"
	" message in case of success
	"
	if l:currentbuffer == bufname("%")
		let s:C_HlMessage = " CodeCheck --- no warnings for : ".l:currentbuffer
	endif
endfunction    " ----------  end of function C_CodeCheck ----------
"
"------------------------------------------------------------------------------
"  C_Indent : run indent(1)       {{{1
"------------------------------------------------------------------------------
"
function! C_Indent ( mode )
	if !executable("indent")
		let s:C_HlMessage	= ' indent is not executable or not installed! '
		return
	endif
	let	l:currentbuffer=bufname("%")
	if &filetype != "c" && &filetype != "cpp"
		let s:C_HlMessage = ' "'.l:currentbuffer.'" seems not to be a C/C++ file '
		return
	endif
	let s:C_HlMessage    = ""

	if a:mode=="a"
		if C_Input("indent whole file [y/n/Esc] : ", "y" ) != "y"
			return
		endif
		exe	":update"
		if has("MSWIN")
			silent exe ":%!indent"
		else
			silent exe ":%!indent 2> ".s:C_IndentErrorLog
		endif
		let s:C_HlMessage = ' File "'.l:currentbuffer.'" reformatted.'
	endif

	if a:mode=="v"
		if has("MSWIN")
			silent exe ":'<,'>!indent"
		else
			silent exe ":'<,'>!indent 2> ".s:C_IndentErrorLog
		endif
		let s:C_HlMessage = ' File "'.l:currentbuffer.'" (lines '.line("'<").'-'.line("'>").') reformatted. '
	endif

	if v:shell_error != 0
		let s:C_HlMessage = ' Indent reported an error when processing file "'.l:currentbuffer.'". '
	endif

endfunction    " ----------  end of function C_Indent ----------
"
"------------------------------------------------------------------------------
"  C_HlMessage : indent message     {{{1
"------------------------------------------------------------------------------
function! C_HlMessage ()
	echohl Search
	echo s:C_HlMessage
	echohl None
endfunction    " ----------  end of function C_HlMessage ----------
"
"------------------------------------------------------------------------------
"  C_Settings : settings     {{{1
"------------------------------------------------------------------------------
function! C_Settings ()
	let	txt =     " C/C++-Support settings\n\n"
	let txt = txt.'                   author :  "'.s:C_Macro['|AUTHOR|']."\"\n"
	let txt = txt.'                 initials :  "'.s:C_Macro['|AUTHORREF|']."\"\n"
	let txt = txt.'                    email :  "'.s:C_Macro['|EMAIL|']."\"\n"
	let txt = txt.'                  company :  "'.s:C_Macro['|COMPANY|']."\"\n"
	let txt = txt.'                  project :  "'.s:C_Macro['|PROJECT|']."\"\n"
	let txt = txt.'         copyright holder :  "'.s:C_Macro['|COPYRIGHTHOLDER|']."\"\n"
	let txt = txt.'           template style :  "'.s:C_Macro['|STYLE|']."\"\n"
	let txt = txt.'         C / C++ compiler :  '.s:C_CCompiler.' / '.s:C_CplusCompiler."\n"
	let txt = txt.'         C file extension :  "'.s:C_CExtension.'"  (everything else is C++)'."\n"
	let txt = txt.'    extension for objects :  "'.s:C_ObjExtension."\"\n"
	let txt = txt.'extension for executables :  "'.s:C_ExeExtension."\"\n"
	let txt = txt.'           compiler flags :  "'.s:C_CFlags."\"\n"
	let txt = txt.'             linker flags :  "'.s:C_LFlags."\"\n"
	let txt = txt.'                libraries :  "'.s:C_Libs."\"\n"
	let txt = txt.'   code snippet directory :  '.s:C_CodeSnippets."\n"
	if s:installation == 'system'
		let txt = txt.'global template directory :  '.s:C_GlobalTemplateDir."\n"
		if filereadable( s:C_LocalTemplateFile )
			let txt = txt.' local template directory :  '.s:C_LocalTemplateDir."\n"
		endif
	else
		let txt = txt.' local template directory :  '.s:C_GlobalTemplateDir."\n"
	endif
	if	!s:MSWIN
		let txt = txt.'           xterm defaults :  '.s:C_XtermDefaults."\n"
	endif
	" ----- dictionaries ------------------------
	if g:C_Dictionary_File != ""
		let ausgabe= substitute( g:C_Dictionary_File, ",", ",\n                           + ", "g" )
		let txt = txt."       dictionary file(s) :  ".ausgabe."\n"
	endif
	let txt = txt.'     current output dest. :  '.s:C_OutputGvim."\n"
	" ----- splint ------------------------------
	if s:C_SplintIsExecutable==1
		if exists("b:C_SplintCmdLineArgs")
			let ausgabe = b:C_SplintCmdLineArgs
		else
			let ausgabe = ""
		endif
		let txt = txt."        splint options(s) :  ".ausgabe."\n"
	endif
	" ----- code check --------------------------
	if s:C_CodeCheckIsExecutable==1
		if exists("b:C_CodeCheckCmdLineArgs")
			let ausgabe = b:C_CodeCheckCmdLineArgs
		else
			let ausgabe = s:C_CodeCheckOptions
		endif
		let txt = txt."CodeCheck (TM) options(s) :  ".ausgabe."\n"
	endif
	let txt = txt."\n"
	let	txt = txt."__________________________________________________________________________\n"
	let	txt = txt." C/C++-Support, Version ".g:C_Version." / Dr.-Ing. Fritz Mehner / mehner@fh-swf.de\n\n"
	echo txt
endfunction    " ----------  end of function C_Settings ----------
"
"------------------------------------------------------------------------------
"  C_Hardcopy : hardcopy     {{{1
"    MSWIN : a printer dialog is displayed
"    other : print PostScript to file
"------------------------------------------------------------------------------
function! C_Hardcopy (arg1)
	let Sou	= expand("%")
  if Sou == ""
		redraw
		echohl WarningMsg | echo "no file name " | echohl None
		return
  endif
	let	Sou		= escape(Sou,s:escfilename)		" name of the file in the current buffer
	let	old_printheader=&printheader
	exe  ':set printheader='.s:C_Printheader
	" ----- normal mode ----------------
	if a:arg1=="n"
		silent exe	"hardcopy > ".Sou.".ps"
		if	!s:MSWIN
			echo "file \"".Sou."\" printed to \"".Sou.".ps\""
		endif
	endif
	" ----- visual mode ----------------
	if a:arg1=="v"
		silent exe	"*hardcopy > ".Sou.".ps"
		if	!s:MSWIN
			echo "file \"".Sou."\" (lines ".line("'<")."-".line("'>").") printed to \"".Sou.".ps\""
		endif
	endif
	exe  ':set printheader='.escape( old_printheader, ' %' )
endfunction    " ----------  end of function C_Hardcopy ----------
"
"------------------------------------------------------------------------------
"  C_HelpCsupport : help csupport     {{{1
"------------------------------------------------------------------------------
function! C_HelpCsupport ()
	try
		:help csupport
	catch
		exe ':helptags '.s:plugin_dir.'doc'
		:help csupport
	endtry
endfunction    " ----------  end of function C_HelpCsupport ----------
"
"------------------------------------------------------------------------------
"  C_Help : lookup word under the cursor or ask    {{{1
"------------------------------------------------------------------------------
"
let s:C_DocBufferName       = "C_HELP"
let s:C_DocHelpBufferNumber = -1
"
function! C_Help( type )

	let cuc		= getline(".")[col(".") - 1]		" character under the cursor
	let	item	= expand("<cword>")							" word under the cursor
	if cuc == '' || item == "" || match( item, cuc ) == -1
		let	item=C_Input('name of the manual page : ', '' )
	endif

	if item == ""
		return
	endif
	"------------------------------------------------------------------------------
	"  replace buffer content with bash help text
	"------------------------------------------------------------------------------
	"
	" jump to an already open bash help window or create one
	"
	if bufloaded(s:C_DocBufferName) != 0 && bufwinnr(s:C_DocHelpBufferNumber) != -1
		exe bufwinnr(s:C_DocHelpBufferNumber) . "wincmd w"
		" buffer number may have changed, e.g. after a 'save as'
		if bufnr("%") != s:C_DocHelpBufferNumber
			let s:C_DocHelpBufferNumber=bufnr(s:C_OutputBufferName)
			exe ":bn ".s:C_DocHelpBufferNumber
		endif
	else
		exe ":new ".s:C_DocBufferName
		let s:C_DocHelpBufferNumber=bufnr("%")
		setlocal buftype=nofile
		setlocal noswapfile
		setlocal bufhidden=delete
		setlocal filetype=sh		" allows repeated use of <S-F1>
		setlocal syntax=OFF
	endif
	setlocal	modifiable
	"
	if a:type == 'm' 
		"
		" Is there more than one manual ?
		"
		let manpages	= system( s:C_Man.' -k '.item )
		if v:shell_error
			echomsg	"Shell command '".s:C_Man." -k ".item."' failed."
			:close
			return
		endif
		let	catalogs	= split( manpages, '\n', )
		let	manual		= {}
		"
		" Select manuals where the name exactly matches
		"
		for line in catalogs
			if line =~ '^'.item.'\s\+(' 
				let	itempart	= split( line, '\s\+' )
				let	catalog		= itempart[1][1:-2]
				if match( catalog, '.p$' ) == -1
					let	manual[catalog]	= catalog
				endif
			endif
		endfor
		"
		" Build a selection list if there are more than one manual
		"
		let	catalog	= ""
		if len(keys(manual)) > 1
			for key in keys(manual)
				echo ' '.item.'  '.key
			endfor
			let defaultcatalog	= ''
			if has_key( manual, '3' )
				let defaultcatalog	= '3'
			else
				if has_key( manual, '2' )
					let defaultcatalog	= '2'
				endif
			endif
			let	catalog	= input( 'select manual section (<Enter> cancels) : ', defaultcatalog )
			if ! has_key( manual, catalog )
				:close
				:redraw
				echomsg	"no appropriate manual section '".catalog."'"
				return
			endif
		endif

		set filetype=man
		silent exe ":%!".s:C_Man." ".catalog." ".item

	endif

	setlocal nomodifiable
endfunction		" ---------- end of function  C_Help  ----------

"------------------------------------------------------------------------------
"  C_CreateGuiMenus     {{{1
"------------------------------------------------------------------------------
let s:C_MenuVisible = 0								" state variable controlling the C-menus
"
function! C_CreateGuiMenus ()
	if s:C_MenuVisible != 1
		aunmenu <silent> &Tools.Load\ C\ Support
		amenu   <silent> 40.1000 &Tools.-SEP100- :
		amenu   <silent> 40.1030 &Tools.Unload\ C\ Support <C-C>:call C_RemoveGuiMenus()<CR>
		call C_InitMenus()
		let s:C_MenuVisible = 1
	endif
endfunction    " ----------  end of function C_CreateGuiMenus  ----------

"------------------------------------------------------------------------------
"  C_ToolMenu     {{{1
"------------------------------------------------------------------------------
function! C_ToolMenu ()
	amenu   <silent> 40.1000 &Tools.-SEP100- :
	amenu   <silent> 40.1030 &Tools.Load\ C\ Support      :call C_CreateGuiMenus()<CR>
	imenu   <silent> 40.1030 &Tools.Load\ C\ Support <C-C>:call C_CreateGuiMenus()<CR>
endfunction    " ----------  end of function C_ToolMenu  ----------

"------------------------------------------------------------------------------
"  C_RemoveGuiMenus     {{{1
"------------------------------------------------------------------------------
function! C_RemoveGuiMenus ()
	if s:C_MenuVisible == 1
		if s:C_Root == ""
			aunmenu <silent> Comments
			aunmenu <silent> Statements
			aunmenu <silent> Preprocessor
			aunmenu <silent> Idioms
			aunmenu <silent> Snippets
			aunmenu <silent> C++
			aunmenu <silent> Run
		else
			exe "aunmenu <silent> ".s:C_Root
		endif
		"
		aunmenu <silent> &Tools.Unload\ C\ Support
		call C_ToolMenu()
		"
		let s:C_MenuVisible = 0
	endif
endfunction    " ----------  end of function C_RemoveGuiMenus  ----------

"------------------------------------------------------------------------------
"  C_RereadTemplates     {{{1
"  rebuild commands and the menu from the (changed) template file
"------------------------------------------------------------------------------
function! C_RereadTemplates ()
    let s:C_Template     = {}
    let s:C_FileVisited  = []
    call C_ReadTemplates(s:C_GlobalTemplateFile)
    echomsg "templates rebuilt from '".s:C_GlobalTemplateFile."'"
		"
		if s:installation == 'system' && filereadable( s:C_LocalTemplateFile )
			call C_ReadTemplates( s:C_LocalTemplateFile )
			echomsg " and from '".s:C_LocalTemplateFile."'"
		endif
endfunction    " ----------  end of function C_RereadTemplates  ----------

"------------------------------------------------------------------------------
"  C_EditTemplates     {{{1
"------------------------------------------------------------------------------
function! C_EditTemplates ( type )
	"
	if a:type == 'global'
		if s:installation == 'system'
			if filereadable( s:C_GlobalTemplateFile )
				if has("browse")
					let	l:templatefile	= browse(0,"edit a template file",s:C_GlobalTemplateDir,"")
				else
					let	l:templatefile	= input("edit a template file", s:C_GlobalTemplateDir, "file" )
				endif
				if l:templatefile != ""
					:execute "update! | split | edit ".l:templatefile
				endif
			else
				echomsg "global template file not readable"
			endif
		else
			echomsg "C/C++-Support is user installed: no global template file"
		endif
	endif
	"
	if a:type == 'local'
		if s:installation == 'system'
			if filereadable( s:C_LocalTemplateFile )
				if has("browse")
					let	l:templatefile	= browse(0,"edit a template file",s:C_LocalTemplateDir,"")
				else
					let	l:templatefile=input("edit a template file", s:C_LocalTemplateDir, "file" )
				endif
				if l:templatefile != ""
					:execute "update! | split | edit ".l:templatefile
				endif
			else
				echomsg "local template file not readable"
			endif
		else
			if filereadable( s:C_GlobalTemplateFile )
				if has("browse")
					let	l:templatefile	= browse(0,"edit a template file",s:C_GlobalTemplateDir,"")
				else
					let	l:templatefile	= input("edit a template file", s:C_GlobalTemplateDir, "file" )
				endif
				if l:templatefile != ""
					:execute "update! | split | edit ".l:templatefile
				endif
			else
				echomsg "local template file not readable"
			endif
		endif
	endif
	"
endfunction    " ----------  end of function C_EditTemplates  ----------
"
"------------------------------------------------------------------------------
"  C_ReadTemplates     {{{1
"  read the template file(s), build the macro and the template dictionary
"
"------------------------------------------------------------------------------
function! C_ReadTemplates ( templatefile )

  if !filereadable( a:templatefile )
    echohl WarningMsg
    echomsg "C/C++ template file '".a:templatefile."' does not exist or is not readable"
    echohl None
    return
  endif

	let	skipmacros	= 0
  let s:C_FileVisited  += [a:templatefile]

  "------------------------------------------------------------------------------
  "  read template file, start with an empty template dictionary
  "------------------------------------------------------------------------------

  let item  = ''
	let	skipline	= 0
  for line in readfile( a:templatefile )
		" if not a comment :
    if line !~ s:C_MacroCommentRegex
      "
			" IF
      "
      let string  = matchlist( line, s:C_TemplateIf )
      if !empty(string) 
				if s:C_Macro['|STYLE|'] != string[1]
					let	skipline	= 1
				endif
			endif
			"
			" ENDIF
      "
      let string  = matchlist( line, s:C_TemplateEndif )
      if !empty(string)
				let	skipline	= 0
				continue
			endif
			"
      if skipline == 1
				continue
			endif
      "
      " macros and file includes
      "
      let string  = matchlist( line, s:C_MacroLineRegex )
      if !empty(string) && skipmacros == 0
        let key = '|'.string[1].'|'
        let val = string[2]
        let val = substitute( val, '\s\+$', '', '' )
        let val = substitute( val, "[\"\']$", '', '' )
        let val = substitute( val, "^[\"\']", '', '' )
        "
        if key == '|includefile|' && count( s:C_FileVisited, val ) == 0
					let path   = fnamemodify( a:templatefile, ":p:h" )
          call C_ReadTemplates( path.'/'.val )    " recursive call
        else
          let s:C_Macro[key] = escape( val, '&' )
        endif
        continue                                            " next line
      endif
      "
      " single template header
      "
      let name  = matchstr( line, s:C_TemplateLineRegex )
      "
      if name != ''
        let part  = split( name, '\s*==\s*')
        let item  = part[0]
        if has_key( s:C_Template, item ) && s:C_TemplateOverwrittenMsg == 'yes'
          echomsg "existing C/C++ template '".item."' overwritten"
        endif
        let s:C_Template[item] = ''
				let skipmacros	= 1
        "
        let s:C_Attribute[item] = 'below'
        if has_key( s:Attribute, get( part, 1, 'NONE' ) )
          let s:C_Attribute[item] = part[1]
        endif
      else
        if item != ''
          let s:C_Template[item] = s:C_Template[item].line."\n"
        endif
      endif
    endif
		"
  endfor	" ---------  read line  ---------

	call C_SetSmallCommentStyle()
endfunction    " ----------  end of function C_ReadTemplates  ----------

"------------------------------------------------------------------------------
" C_OpenFold     {{{1
" Open fold and go to the first or last line of this fold. 
"------------------------------------------------------------------------------
function! C_OpenFold ( mode )
	if foldclosed(".") >= 0
		" we are on a closed  fold: get end position, open fold, jump to the
		" last line of the previously closed fold
		let	foldstart	= foldclosed(".")
		let	foldend		= foldclosedend(".")
		normal zv
		if a:mode == 'below'
			exe ":".foldend
		endif
		if a:mode == 'start'
			exe ":".foldstart
		endif
	endif
endfunction    " ----------  end of function C_OpenFold  ----------

"------------------------------------------------------------------------------
"  C_InsertTemplate     {{{1
"  insert a template from the template dictionary
"  do macro expansion
"------------------------------------------------------------------------------
function! C_InsertTemplate ( key, ... )

	if !has_key( s:C_Template, a:key )
		echomsg "Template '".a:key."' not found. Please check your template file in '".s:C_GlobalTemplateDir."'"
		return
	endif

	if &foldenable 
		let	foldmethod_save	= &foldmethod
		set foldmethod=manual
	endif
  "------------------------------------------------------------------------------
  "  insert the user macros
  "------------------------------------------------------------------------------

	" use internal formatting to avoid conficts when using == below
	"
	let	equalprg_save	= &equalprg
	set equalprg=

  let mode  = s:C_Attribute[a:key]

	" remove <SPLIT> and insert the complete macro
	"
	if a:0 == 0
		let val = C_ExpandUserMacros (a:key)
		if val	== ""
			return
		endif
		let val	= C_ExpandSingleMacro( val, '<SPLIT>', '' )

		if mode == 'below'
			call C_OpenFold('below')
			let pos1  = line(".")+1
			put  =val
			let pos2  = line(".")
			" proper indenting
			exe ":".pos1
			let ins	= pos2-pos1+1
			exe "normal ".ins."=="
			"
		elseif mode == 'above'
			let pos1  = line(".")
			put! =val
			let pos2  = line(".")
			" proper indenting
			exe ":".pos1
			let ins	= pos2-pos1+1
			exe "normal ".ins."=="
			"
		elseif mode == 'start'
			normal gg
			call C_OpenFold('start')
			let pos1  = 1
			put! =val
			let pos2  = line(".")
			" proper indenting
			exe ":".pos1
			let ins	= pos2-pos1+1
			exe "normal ".ins."=="
			"
		elseif mode == 'append'
			if &foldenable && foldclosed(".") >= 0
				echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
				exe "set foldmethod=".foldmethod_save
				return
			else
				let pos1  = line(".")
				put =val
				let pos2  = line(".")-1
				exe ":".pos1
				:join!
			endif
			"
		elseif mode == 'insert'
			if &foldenable && foldclosed(".") >= 0
				echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
				exe "set foldmethod=".foldmethod_save
				return
			else
				let val   = substitute( val, '\n$', '', '' )
				let currentline	= getline( "." )
				let pos1  = line(".")
				let pos2  = pos1 + count( split(val,'\zs'), "\n" )
				" assign to the unnamed register "" :
				let @"=val
				normal p
				" reformat only multiline inserts and previously empty lines
				if pos2-pos1 > 0 || currentline =~ ''
					exe ":".pos1
					let ins	= pos2-pos1+1
					exe "normal ".ins."=="
				endif
			endif
			"
		endif
		"
	else
		"
		" =====  visual mode  ===============================
		"
		if  a:1 == 'v'
			let val = C_ExpandUserMacros (a:key)
			let val	= C_ExpandSingleMacro( val, s:C_TemplateJumpTarget2, '' )
			if val	== ""
				return
			endif

			if match( val, '<SPLIT>\s*\n' ) >= 0
				let part	= split( val, '<SPLIT>\s*\n' )
			else
				let part	= split( val, '<SPLIT>' )
			endif

			if len(part) < 2
				let part	= [ "" ] + part
				echomsg 'SPLIT missing in template '.a:key
			endif
			"
			" 'visual' and mode 'insert':
			"   <part0><marked area><part1>
			" part0 and part1 can consist of several lines
			"
			if mode == 'insert'
				let pos1  = line(".")
				let pos2  = pos1
				let	string= @*
				let replacement	= part[0].string.part[1]
				" remove trailing '\n'
				let replacement   = substitute( replacement, '\n$', '', '' )
				exe ':s/'.string.'/'.replacement.'/'
			endif
			"
			" 'visual' and mode 'below':
			"   <part0>
			"   <marked area>
			"   <part1>
			" part0 and part1 can consist of several lines
			"
			if mode == 'below'

				:'<put! =part[0]
				:'>put  =part[1]

				let pos1  = line("'<") - len(split(part[0], '\n' ))
				let pos2  = line("'>") + len(split(part[1], '\n' ))
				""			echo part[0] part[1] pos1 pos2
				"			" proper indenting
				exe ":".pos1
				let ins	= pos2-pos1+1
				exe "normal ".ins."=="
			endif
			"
		endif		" ---------- end visual mode
	endif

	" restore formatter programm
	let &equalprg	= equalprg_save

  "------------------------------------------------------------------------------
  "  position the cursor
  "------------------------------------------------------------------------------
  exe ":".pos1
  let mtch = search( '<CURSOR>', 'c', pos2 )
	if mtch != 0
		let line	= getline(mtch)
		if line =~ '<CURSOR>$'
			call setline( mtch, substitute( line, '<CURSOR>', '', '' ) )
			if  a:0 != 0 && a:1 == 'v' && getline(".") =~ '^\s*$'
				normal J
			else
				:startinsert!
			endif
		else
			call setline( mtch, substitute( line, '<CURSOR>', '', '' ) )
			:startinsert
		endif
	else
		" to the end of the block; needed for repeated inserts
		if mode == 'below'
			exe ":".pos2
		endif
  endif

  "------------------------------------------------------------------------------
  "  marked words
  "------------------------------------------------------------------------------
	" define a pattern to highlight
	call C_HighlightJumpTargets ()

	if &foldenable 
		" restore folding method
		exe "set foldmethod=".foldmethod_save
		normal zv
	endif

endfunction    " ----------  end of function C_InsertTemplate  ----------

"------------------------------------------------------------------------------
"  C_HighlightJumpTargets
"------------------------------------------------------------------------------
function! C_HighlightJumpTargets ()
	if s:C_Ctrl_j == 'on'
		exe 'match Search /'.s:C_TemplateJumpTarget1.'\|'.s:C_TemplateJumpTarget2.'/'
	endif
endfunction    " ----------  end of function C_HighlightJumpTargets  ----------

"------------------------------------------------------------------------------
"  C_JumpCtrlJ     {{{1
"------------------------------------------------------------------------------
function! C_JumpCtrlJ ()
  let match	= search( s:C_TemplateJumpTarget1.'\|'.s:C_TemplateJumpTarget2, 'c' )
	if match > 0
		" remove the target
		call setline( match, substitute( getline('.'), s:C_TemplateJumpTarget1.'\|'.s:C_TemplateJumpTarget2, '', '' ) )
	else
		" try to jump behind parenthesis or strings 
		call search( "[\]})\"'`]", 'W' )
		normal l
	endif
	return ''
endfunction    " ----------  end of function C_JumpCtrlJ  ----------

"------------------------------------------------------------------------------
"  C_ExpandUserMacros     {{{1
"------------------------------------------------------------------------------
function! C_ExpandUserMacros ( key )

  let template 								= s:C_Template[ a:key ]
	let	s:C_ExpansionCounter		= {}										" reset the expansion counter

  "------------------------------------------------------------------------------
  "  renew the predefined macros and expand them
	"  can be replaced, with e.g. |?DATE|
  "------------------------------------------------------------------------------
	let	s:C_Macro['|BASENAME|']	= toupper(expand("%:t:r"))
  let s:C_Macro['|DATE|']  		= C_DateAndTime('d')
  let s:C_Macro['|FILENAME|'] = expand("%:t")
  let s:C_Macro['|PATH|']  		= expand("%:p:h")
  let s:C_Macro['|SUFFIX|'] 	= expand("%:e")
  let s:C_Macro['|TIME|']  		= C_DateAndTime('t')
  let s:C_Macro['|YEAR|']  		= C_DateAndTime('y')

  "------------------------------------------------------------------------------
  "  delete jump targets if mapping for C-j is off
  "------------------------------------------------------------------------------
	if s:C_Ctrl_j == 'off'
		let template	= substitute( template, s:C_TemplateJumpTarget1.'\|'.s:C_TemplateJumpTarget2, '', 'g' )
	endif

  "------------------------------------------------------------------------------
  "  look for replacements
  "------------------------------------------------------------------------------
	while match( template, s:C_ExpansionRegex ) != -1
		let macro				= matchstr( template, s:C_ExpansionRegex )
		let replacement	= substitute( macro, '?', '', '' )
		let template		= substitute( template, macro, replacement, "g" )

		let match	= matchlist( macro, s:C_ExpansionRegex )

		if match[1] != ''
			let macroname	= '|'.match[1].'|'
			"
			" notify flag action, if any
			let flagaction	= ''
			if has_key( s:C_MacroFlag, match[2] )
				let flagaction	= ' (-> '.s:C_MacroFlag[ match[2] ].')'
			endif
			"
			" ask for a replacement
			if has_key( s:C_Macro, macroname )
				let	name	= C_Input( match[1].flagaction.' : ', C_ApplyFlag( s:C_Macro[macroname], match[2] ) )
			else
				let	name	= C_Input( match[1].flagaction.' : ', '' )
			endif
			if name == ""
				return ""
			endif
			"
			" keep the modified name
			let s:C_Macro[macroname]  			= C_ApplyFlag( name, match[2] )
		endif
	endwhile

  "------------------------------------------------------------------------------
  "  do the actual macro expansion
	"  loop over the macros found in the template
  "------------------------------------------------------------------------------
	while match( template, s:C_NonExpansionRegex ) != -1

		let macro			= matchstr( template, s:C_NonExpansionRegex )
		let match			= matchlist( macro, s:C_NonExpansionRegex )

		if match[1] != ''
			let macroname	= '|'.match[1].'|'

			if has_key( s:C_Macro, macroname )
				"-------------------------------------------------------------------------------
				"   check for recursion
				"-------------------------------------------------------------------------------
				if has_key( s:C_ExpansionCounter, macroname )
					let	s:C_ExpansionCounter[macroname]	+= 1
				else
					let	s:C_ExpansionCounter[macroname]	= 0
				endif
				if s:C_ExpansionCounter[macroname]	>= s:C_ExpansionLimit
					echomsg " recursion terminated for recursive macro ".macroname
					return template
				endif
				"-------------------------------------------------------------------------------
				"   replace
				"-------------------------------------------------------------------------------
				let replacement = C_ApplyFlag( s:C_Macro[macroname], match[2] )
				let template 		= substitute( template, macro, replacement, "g" )
			else
				"
				" macro not yet defined
				let s:C_Macro['|'.match[1].'|']  		= ''
			endif
		endif

	endwhile

  return template
endfunction    " ----------  end of function C_ExpandUserMacros  ----------

"------------------------------------------------------------------------------
"  C_ApplyFlag     {{{1
"------------------------------------------------------------------------------
function! C_ApplyFlag ( val, flag )
	"
	" l : lowercase
	if a:flag == ':l'
		return  tolower(a:val)
	endif
	"
	" u : uppercase
	if a:flag == ':u'
		return  toupper(a:val)
	endif
	"
	" c : capitalize
	if a:flag == ':c'
		return  toupper(a:val[0]).a:val[1:]
	endif
	"
	" L : legalized name
	if a:flag == ':L'
		return  C_LegalizeName(a:val)
	endif
	"
	" flag not valid
	return a:val
endfunction    " ----------  end of function C_ApplyFlag  ----------
"
"------------------------------------------------------------------------------
"  C_ExpandSingleMacro     {{{1
"------------------------------------------------------------------------------
function! C_ExpandSingleMacro ( val, macroname, replacement )
  return substitute( a:val, escape(a:macroname, '$' ), a:replacement, "g" )
endfunction    " ----------  end of function C_ExpandSingleMacro  ----------

"------------------------------------------------------------------------------
"  C_SetSmallCommentStyle     {{{1
"------------------------------------------------------------------------------
function! C_SetSmallCommentStyle ()
	if has_key( s:C_Template, 'comment.end-of-line-comment' )
		if match( s:C_Template['comment.end-of-line-comment'], '^\s*/\*' ) != -1
			let s:C_Com1          = '/*'     " C-style : comment start
			let s:C_Com2          = '*/'     " C-style : comment end
		else
			let s:C_Com1          = '//'     " C++style : comment start
			let s:C_Com2          = ''       " C++style : comment end
		endif
	endif
endfunction    " ----------  end of function C_SetSmallCommentStyle  ----------

"------------------------------------------------------------------------------
"  C_InsertMacroValue     {{{1
"------------------------------------------------------------------------------
function! C_InsertMacroValue ( key )
	if s:C_Macro['|'.a:key.'|'] == ''
		echomsg 'the tag |'.a:key.'| is empty'
		return
	endif
	"
	if &foldenable && foldclosed(".") >= 0
		echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
		return
	endif
	if col(".") > 1
		exe 'normal a'.s:C_Macro['|'.a:key.'|']
	else
		exe 'normal i'.s:C_Macro['|'.a:key.'|']
	endif
endfunction    " ----------  end of function C_InsertMacroValue  ----------

"------------------------------------------------------------------------------
"  insert date and time     {{{1
"------------------------------------------------------------------------------
function! C_InsertDateAndTime ( format )
	if &foldenable && foldclosed(".") >= 0
		echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
		return ""
	endif
	if col(".") > 1
		exe 'normal a'.C_DateAndTime(a:format)
	else
		exe 'normal i'.C_DateAndTime(a:format)
	endif
endfunction    " ----------  end of function C_InsertDateAndTime  ----------

"------------------------------------------------------------------------------
"  generate date and time     {{{1
"------------------------------------------------------------------------------
function! C_DateAndTime ( format )
	if a:format == 'd'
		return strftime( s:C_FormatDate )
	elseif a:format == 't'
		return strftime( s:C_FormatTime )
	elseif a:format == 'dt'
		return strftime( s:C_FormatDate ).' '.strftime( s:C_FormatTime )
	elseif a:format == 'y'
		return strftime( s:C_FormatYear )
	endif
endfunction    " ----------  end of function C_DateAndTime  ----------

"------------------------------------------------------------------------------
"  check for header or implementation file     {{{1
"------------------------------------------------------------------------------
function! C_InsertTemplateWrapper ()
	if index( s:C_SourceCodeExtensionsList, expand('%:e') ) >= 0 
		call C_InsertTemplate("comment.file-description")
	else
		call C_InsertTemplate("comment.file-description-header")
	endif
endfunction    " ----------  end of function C_InsertTemplateWrapper  ----------

"
"-------------------------------------------------------------------------------
"   Comment : C/C++ File Sections             {{{1
"-------------------------------------------------------------------------------
let s:CFileSectionOrdered	= [ 
	\ "Header\ File\ Includes", 
	\ "Local\ Macros"					, 
	\ "Local\ Type\ Def\."		, 
	\ "Local\ Data\ Types"		, 
	\ "Local\ Variables"			, 
	\ "Local\ Prototypes"			, 
	\ "Exp\.\ Function\ Def\.", 
	\ "Local\ Function\ Def\.", 
	\ "Local\ Class\ Def\."		, 
	\ "Exp\.\ Class\ Impl\."	, 
	\ "Local\ Class\ Impl\."	, 
	\ "All\ sections,\ C"		  ,
	\ "All\ sections,\ C++"	  ,
	\ ]

let s:CFileSection	= { 
	\ "Header\ File\ Includes" : "file-section-cpp-header-includes"               , 
	\ "Local\ Macros"					 : "file-section-cpp-macros"                        , 
	\ "Local\ Type\ Def\."		 : "file-section-cpp-typedefs"                      , 
	\ "Local\ Data\ Types"		 : "file-section-cpp-data-types"                    , 
	\ "Local\ Variables"			 : "file-section-cpp-local-variables"               , 
	\ "Local\ Prototypes"			 : "file-section-cpp-prototypes"                    , 
	\ "Exp\.\ Function\ Def\." : "file-section-cpp-function-defs-exported"        , 
	\ "Local\ Function\ Def\." : "file-section-cpp-function-defs-local"           , 
	\ "Local\ Class\ Def\."		 : "file-section-cpp-class-defs"                    , 
	\ "Exp\.\ Class\ Impl\."	 : "file-section-cpp-class-implementations-exported", 
	\ "Local\ Class\ Impl\."	 : "file-section-cpp-class-implementations-local"   , 
	\ "All\ sections,\ C"			 : "c",
	\ "All\ sections,\ C++"		 : "cpp",
	\ }

function!	C_CFileSectionList ( ArgLead, CmdLine, CursorPos )
	"
	" show all types
	if a:ArgLead == ''
		return s:CFileSectionOrdered
	endif
	"
	" show types beginning with a:ArgLead
	let	expansions	= []
	for item in keys(s:CFileSection)
		if match( item, '\<'.a:ArgLead.'\w*' ) == 0
			call add( expansions, item )
		endif
	endfor
	return	expansions
endfunction    " ----------  end of function C_CFileSectionList  ----------

function! C_CFileSectionListInsert ( arg )
	if has_key( s:CFileSection, a:arg )
		if s:CFileSection[a:arg] == 'c' || s:CFileSection[a:arg] == 'cpp'
			call C_Comment_C_SectionAll( 'comment.'.s:CFileSection[a:arg] )
			return 
		endif
		call C_InsertTemplate( 'comment.'.s:CFileSection[a:arg] )
	else
		echomsg "entry ".a:arg." does not exist"
	endif
endfunction    " ----------  end of function C_CFileSectionListInsert  ----------
"
"-------------------------------------------------------------------------------
"   Comment : H File Sections             {{{1
"-------------------------------------------------------------------------------
let s:HFileSectionOrdered	= [ 
	\	"Header\ File\ Includes"   ,
	\	"Exported\ Macros"         ,
	\	"Exported\ Type\ Def\."    ,
	\	"Exported\ Data\ Types"    ,
	\	"Exported\ Variables"      ,
	\	"Exported\ Funct\.\ Decl\.",
	\	"Exported\ Class\ Def\."   ,
	\	"All\ sections,\ C"        ,
	\	"All\ sections,\ C++"      ,
	\ ]

let s:HFileSection	= { 
	\	"Header\ File\ Includes"    : "file-section-hpp-header-includes"               ,
	\	"Exported\ Macros"          : "file-section-hpp-macros"                        ,
	\	"Exported\ Type\ Def\."     : "file-section-hpp-exported-typedefs"             ,
	\	"Exported\ Data\ Types"     : "file-section-hpp-exported-data-types"           ,
	\	"Exported\ Variables"       : "file-section-hpp-exported-variables"            ,
	\	"Exported\ Funct\.\ Decl\." : "file-section-hpp-exported-function-declarations",
	\	"Exported\ Class\ Def\."    : "file-section-hpp-exported-class-defs"           ,
	\	"All\ sections,\ C"         : "c"                                              ,
	\	"All\ sections,\ C++"       : "cpp"                                            ,
	\ }

function!	C_HFileSectionList ( ArgLead, CmdLine, CursorPos )
	"
	" show all types
	if a:ArgLead == ''
		return s:HFileSectionOrdered
	endif
	"
	" show types beginning with a:ArgLead
	let	expansions	= []
	for item in keys(s:HFileSection)
		if match( item, '\<'.a:ArgLead.'\w*' ) == 0
			call add( expansions, item )
		endif
	endfor
	return	expansions
endfunction    " ----------  end of function C_HFileSectionList  ----------

function! C_HFileSectionListInsert ( arg )
	if has_key( s:HFileSection, a:arg )
		if s:HFileSection[a:arg] == 'c' || s:HFileSection[a:arg] == 'cpp'
			call C_Comment_C_SectionAll( 'comment.'.s:HFileSection[a:arg] )
			return 
		endif
		call C_InsertTemplate( 'comment.'.s:HFileSection[a:arg] )
	else
		echomsg "entry ".a:arg." does not exist"
	endif
endfunction    " ----------  end of function C_HFileSectionListInsert  ----------
"
"-------------------------------------------------------------------------------
"   Comment : Keyword Comments             {{{1
"-------------------------------------------------------------------------------
let s:KeywordComment	= { 
	\	'\:BUG\:'          : 'keyword-bug',
	\	'\:COMPILER\:'     : 'keyword-compiler',
	\	'\:TODO\:'         : 'keyword-todo',
	\	'\:TRICKY\:'       : 'keyword-tricky',
	\	'\:WARNING\:'      : 'keyword-warning',
	\	'\:WORKAROUND\:'   : 'keyword-workaround',
	\	'\:new\ keyword\:' : 'keyword-keyword',
	\ }

function!	C_KeywordCommentList ( ArgLead, CmdLine, CursorPos )
	"
	" show all types
	if a:ArgLead == ''
		return sort(keys(s:KeywordComment))
	endif
	"
	" show types beginning with a:ArgLead
	let	expansions	= []
	for item in keys(s:KeywordComment)
		if match( item, '\<'.a:ArgLead.'\w*' ) == 0
			call add( expansions, item )
		endif
	endfor
	return	expansions
endfunction    " ----------  end of function C_KeywordCommentList  ----------

function! C_KeywordCommentListInsert ( arg )
	if has_key( s:KeywordComment, a:arg )
		if s:KeywordComment[a:arg] == 'c' || s:KeywordComment[a:arg] == 'cpp'
			call C_Comment_C_SectionAll( 'comment.'.s:KeywordComment[a:arg] )
			return 
		endif
		call C_InsertTemplate( 'comment.'.s:KeywordComment[a:arg] )
	else
		echomsg "entry ".a:arg." does not exist"
	endif
endfunction    " ----------  end of function C_KeywordCommentListInsert  ----------
"
"-------------------------------------------------------------------------------
"   Comment : Special Comments             {{{1
"-------------------------------------------------------------------------------
let s:SpecialComment	= { 
	\	'EMPTY'                                    : 'special-empty' ,
	\	'FALL\ THROUGH'                            : 'special-fall-through' ,
	\	'IMPL\.\ TYPE\ CONV'                       : 'special-implicit-type-conversion")' ,
	\	'NO\ RETURN'                               : 'special-no-return' ,
	\	'NOT\ REACHED'                             : 'special-not-reached' ,
	\	'TO\ BE\ IMPL\.'                           : 'special-remains-to-be-implemented' ,
	\	'constant\ type\ is\ long\ (L)'            : 'special-constant-type-is-long' ,
	\	'constant\ type\ is\ unsigned\ (U)'        : 'special-constant-type-is-unsigned' ,
	\	'constant\ type\ is\ unsigned\ long\ (UL)' : 'special-constant-type-is-unsigned-long' ,
	\ }

function!	C_SpecialCommentList ( ArgLead, CmdLine, CursorPos )
	"
	" show all types
	if a:ArgLead == ''
		return sort(keys(s:SpecialComment))
	endif
	"
	" show types beginning with a:ArgLead
	let	expansions	= []
	for item in keys(s:SpecialComment)
		if match( item, '\<'.a:ArgLead.'\w*' ) == 0
			call add( expansions, item )
		endif
	endfor
	return	expansions
endfunction    " ----------  end of function C_SpecialCommentList  ----------

function! C_SpecialCommentListInsert ( arg )
	if has_key( s:SpecialComment, a:arg )
		if s:SpecialComment[a:arg] == 'c' || s:SpecialComment[a:arg] == 'cpp'
			call C_Comment_C_SectionAll( 'comment.'.s:SpecialComment[a:arg] )
			return 
		endif
		call C_InsertTemplate( 'comment.'.s:SpecialComment[a:arg] )
	else
		echomsg "entry ".a:arg." does not exist"
	endif
endfunction    " ----------  end of function C_SpecialCommentListInsert  ----------

"------------------------------------------------------------------------------
"  show / hide the c-support menus
"  define key mappings (gVim only)
"------------------------------------------------------------------------------
"
if has("gui_running")
	"
	call C_ToolMenu()
	"
	if s:C_LoadMenus == 'yes'
		call C_CreateGuiMenus()
	endif
	"
	nmap  <unique>  <silent>  <Leader>lcs   :call C_CreateGuiMenus()<CR>
	nmap  <unique>  <silent>  <Leader>ucs   :call C_RemoveGuiMenus()<CR>
	"
endif

"------------------------------------------------------------------------------
"  Automated header insertion
"  Local settings for the quickfix window
"------------------------------------------------------------------------------

if has("autocmd")
	"
	"  Automated header insertion (suffixes from the gcc manual)
	"
	autocmd BufNewFile  * if (&filetype=='cpp' || &filetype=='c') |
				\     call C_InsertTemplateWrapper() | endif
	"
	"  *.h has filetype 'cpp' by default; this can be changed to 'c' :
	"
	if s:C_TypeOfH=='c'
		autocmd BufNewFile,BufEnter  *.h  :set filetype=c
	endif
	"
	" C/C++ source code files which should not be preprocessed.
	"
	autocmd BufNewFile,BufRead  *.i  :set filetype=c
	autocmd BufNewFile,BufRead  *.ii :set filetype=cpp
	"
	" Wrap error descriptions in the quickfix window.
	"
	autocmd BufReadPost quickfix  setlocal wrap | setlocal linebreak
	"
	exe 'autocmd BufRead *.'.join( split( s:C_SourceCodeExtensions, '\s\+'), '\|*.' )
				\     .' call C_HighlightJumpTargets()'
	"
endif " has("autocmd")
"
"------------------------------------------------------------------------------
"  READ THE TEMPLATE FILES
"------------------------------------------------------------------------------
call C_ReadTemplates(s:C_GlobalTemplateFile)
if s:installation == 'system' && filereadable( s:C_LocalTemplateFile )
	call C_ReadTemplates( s:C_LocalTemplateFile )
endif

"
"=====================================================================================
" vim: tabstop=2 shiftwidth=2 foldmethod=marker
