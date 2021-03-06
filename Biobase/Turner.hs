{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators #-}

-- | The 'Turner2004' data structure reflects the RNA (and DNA) energy
-- parameters known as the Turner 2004 data set.
--
-- In general, have a look here:
-- <http://rna.urmc.rochester.edu/NNDB/turner04/index.html> where parameters
-- are explained.
--
-- TODO need a "Functor" instance over elements "e". Or alternatively, generic
-- programming to capture stuff going on in 'e'

module Biobase.Turner where


import Control.Lens
import Data.Array.Repa.Index
import Data.ByteString (ByteString(..))
import qualified Data.ByteString
import qualified Data.Map as M
import qualified Data.Vector as V
import qualified Data.Vector.Unboxed as VU
import qualified Data.Vector.Generic as VG
import qualified Data.Vector.Generic.Mutable as VGM
import Data.Primitive.Types

import Biobase.Primary
import Biobase.Secondary
import Data.PrimitiveArray as PA
import Data.PrimitiveArray.Zero



-- | The actual Turner parameters return energies in Double format.

newtype Energy = Energy Double
  deriving (Eq,Ord,Num,Read,Show)

deriving instance Prim Energy
deriving instance VGM.MVector VU.MVector Energy
deriving instance VG.Vector   VU.Vector  Energy
deriving instance VU.Unbox Energy

-- | The Turner model with 'Energy's.

type Turner2004 = Turner2004Model Energy

-- | The Turner energy tables. Parametrized over the storing vector type 'v'
-- and the actual element type 'e'.

data Turner2004Model e = Turner2004Model
  { _stack              :: !(Unboxed PP e)
  , _dangle3            :: !(Unboxed PN e)
  , _dangle5            :: !(Unboxed PN e)
  , _hairpinL           :: !(VU.Vector e)
  , _hairpinMM          :: !(Unboxed PNN e)
  , _hairpinLookup      :: !(M.Map Primary e)
  , _hairpinGGG         :: !e
  , _hairpinCslope      :: !e
  , _hairpinCintercept  :: !e
  , _hairpinC3          :: !e
  , _bulgeL             :: !(VU.Vector e)
  , _bulgeSingleC       :: !e
  , _iloop1x1           :: !(Unboxed PPNN e)
  , _iloop2x1           :: !(Unboxed PPNNN e)
  , _iloop2x2           :: !(Unboxed PPNNNN e)
  , _iloopMM            :: !(Unboxed PNN e)
  , _iloop2x3MM         :: !(Unboxed PNN e)
  , _iloop1xnMM         :: !(Unboxed PNN e)
  , _iloopL             :: !(VU.Vector e)
  , _multiMM            :: !(Unboxed PNN e)
  , _ninio              :: !e
  , _maxNinio           :: !e
  , _multiOffset        :: !e
  , _multiNuc           :: !e
  , _multiHelix         :: !e
  , _multiAsym          :: !e
  , _multiStrain        :: !e
  , _extMM              :: !(Unboxed PNN e)
  , _coaxial            :: !(Unboxed PP e) -- no intervening unpaired nucleotides
  , _coaxStack          :: !(Unboxed PNN e)
  , _tStackCoax         :: !(Unboxed PNN e)
  , _largeLoop          :: !e
  , _termAU             :: !e
  , _intermolecularInit :: !e
  } deriving (Show)

type PP = (Z:.Nuc:.Nuc:.Nuc:.Nuc)
type PN = (Z:.Nuc:.Nuc:.Nuc)
type PNN = (Z:.Nuc:.Nuc:.Nuc:.Nuc)
type PPNN = PP:.Nuc:.Nuc
type PPNNN = PPNN:.Nuc
type PPNNNN = PPNNN:.Nuc

makeLenses ''Turner2004Model

-- | Map a function over all 'e' elements.

emap :: (VU.Unbox e, VU.Unbox e') => (e -> e') -> Turner2004Model e -> Turner2004Model e'
emap f Turner2004Model{..} = Turner2004Model
  { _stack              = PA.map f _stack
  , _dangle3            = PA.map f _dangle3
  , _dangle5            = PA.map f _dangle5
  , _hairpinL           = VU.map f _hairpinL
  , _hairpinMM          = PA.map f _hairpinMM
  , _hairpinLookup      = M.map f _hairpinLookup
  , _hairpinGGG         = f _hairpinGGG
  , _hairpinCslope      = f _hairpinCslope
  , _hairpinCintercept  = f _hairpinCintercept
  , _hairpinC3          = f _hairpinC3
  , _bulgeL             = VU.map f _bulgeL
  , _bulgeSingleC       = f _bulgeSingleC
  , _iloop1x1           = PA.map f _iloop1x1
  , _iloop2x1           = PA.map f _iloop2x1
  , _iloop2x2           = PA.map f _iloop2x2
  , _iloopMM            = PA.map f _iloopMM
  , _iloop2x3MM         = PA.map f _iloop2x3MM
  , _iloop1xnMM         = PA.map f _iloop1xnMM
  , _iloopL             = VU.map f _iloopL
  , _multiMM            = PA.map f _multiMM
  , _ninio              = f _ninio
  , _maxNinio           = f _maxNinio
  , _multiOffset        = f _multiOffset
  , _multiNuc           = f _multiNuc
  , _multiHelix         = f _multiHelix
  , _multiAsym          = f _multiAsym
  , _multiStrain        = f _multiStrain
  , _extMM              = PA.map f _extMM
  , _coaxial            = PA.map f _coaxial
  , _coaxStack          = PA.map f _coaxStack
  , _tStackCoax         = PA.map f _tStackCoax
  , _largeLoop          = f _largeLoop
  , _termAU             = f _termAU
  , _intermolecularInit = f _intermolecularInit
  }

