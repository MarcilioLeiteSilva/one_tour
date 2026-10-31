import React, { useState, useMemo } from 'react';
import {
  Image as ImageIcon,
  Search,
  Upload,
  Link as LinkIcon,
  Check,
  Copy,
  Edit3,
  RefreshCw,
  Sparkles,
  Download,
  Eye,
  X,
} from 'lucide-react';
import { AppImageItem, PbCityItem, PbAttractionItem } from '../types';
import { uploadAdImage, updatePbRecord } from '../services/api';

interface ImagesTabProps {
  cities: PbCityItem[];
  attractions: PbAttractionItem[];
  selectedUf: string;
  onRefresh: () => void;
  isLoading: boolean;
  onNotify: (message: string, type?: 'success' | 'error') => void;
  isAuthenticated: boolean;
  onOpenLogin: () => void;
}

const STORAGE_KEY = 'onetour_custom_app_images';

// Initial verified authentic catalog of all app spots with distinct real photos
const DEFAULT_APP_IMAGES: AppImageItem[] = [
  // --- PERNAMBUCO: CIDADES ---
  {
    id: 'cidade_recife',
    title: 'Recife',
    subtitle: 'Capital Multicultural • Rios, Pontes e Centro Histórico',
    uf: 'PE',
    citySlug: 'recife',
    category: 'cidade',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
      'https://images.unsplash.com/photo-1582650625119-3a31f8418365?auto=format&fit=crop&w=1200&q=80',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg/1280px-BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg',
    ],
  },
  {
    id: 'cidade_porto_de_galinhas',
    title: 'Porto de Galinhas',
    subtitle: 'Ipojuca • Piscinas Naturais, Jangadas e Recifes de Corais',
    uf: 'PE',
    citySlug: 'porto_de_galinhas',
    category: 'cidade',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg/1280px-BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg/1280px-BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg',
    ],
  },
  {
    id: 'cidade_olinda',
    title: 'Olinda',
    subtitle: 'Patrimônio da Humanidade • Ladeiras, Alto da Sé e Barroco',
    uf: 'PE',
    citySlug: 'olinda',
    category: 'cidade',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg/1280px-Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg/1280px-Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg',
      'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1548625361-19597c414902?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  {
    id: 'cidade_carneiros',
    title: 'Praia dos Carneiros',
    subtitle: 'Tamandaré • Capela de São Benedito e Coqueirais',
    uf: 'PE',
    citySlug: 'carneiros',
    category: 'cidade',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg/1280px-Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg/1280px-Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg',
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  {
    id: 'cidade_noronha',
    title: 'Fernando de Noronha',
    subtitle: 'Santuário Ecológico • Baía do Sancho e Vida Marinha',
    uf: 'PE',
    citySlug: 'noronha',
    category: 'cidade',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Morro_Dois_Irm%C3%A3os_em_Fernando_de_Noronha%2C_Pernambuco.jpg/1280px-Morro_Dois_Irm%C3%A3os_em_Fernando_de_Noronha%2C_Pernambuco.jpg',
      'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?auto=format&fit=crop&w=1200&q=80',
    ],
  },

  // --- ALAGOAS: CIDADES ---
  {
    id: 'cidade_maceio',
    title: 'Maceió',
    subtitle: 'Capital das Águas Claras • Pajuçara, Ponta Verde e Gastronomia',
    uf: 'AL',
    citySlug: 'maceio',
    category: 'cidade',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Orla_de_Macei%C3%B3_2023.jpg/1280px-Orla_de_Macei%C3%B3_2023.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Orla_de_Macei%C3%B3_2023.jpg/1280px-Orla_de_Macei%C3%B3_2023.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg/1280px-Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG/1280px-Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG',
    ],
  },
  {
    id: 'cidade_maragogi',
    title: 'Maragogi',
    subtitle: 'Caribe Brasileiro • Galés em Alto-Mar e Costa dos Corais',
    uf: 'AL',
    citySlug: 'maragogi',
    category: 'cidade',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Maragogi_beach_tourist.jpg/1280px-Maragogi_beach_tourist.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Maragogi_beach_tourist.jpg/1280px-Maragogi_beach_tourist.jpg',
      'https://images.unsplash.com/photo-1515238152791-8216bfdf89a7?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  {
    id: 'cidade_milagres',
    title: 'São Miguel dos Milagres',
    subtitle: 'Rota Ecológica • Praia do Toque e Piscinas Esmeralda',
    uf: 'AL',
    citySlug: 'milagres',
    category: 'cidade',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg/1280px-Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg/1280px-Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg',
      'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
    ],
  },

  // --- PERNAMBUCO: ATRAÇÕES ---
  {
    id: 'att_marco_zero',
    title: 'Praça do Marco Zero',
    subtitle: 'Recife Antigo • Esculturas de Brennand e Bacia do Pina',
    uf: 'PE',
    citySlug: 'recife',
    category: 'cultura',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
    ],
  },
  {
    id: 'att_piscinas_porto',
    title: 'Piscinas Naturais de Porto de Galinhas',
    subtitle: 'Porto de Galinhas • Recifes e Peixes Sargentinhos',
    uf: 'PE',
    citySlug: 'porto_de_galinhas',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg/1280px-BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg',
    ],
  },
  {
    id: 'att_alto_da_se',
    title: 'Alto da Sé e Mirante Panorâmico',
    subtitle: 'Olinda • Vista de Recife, Igrejas e Tapiocas Típicas',
    uf: 'PE',
    citySlug: 'olinda',
    category: 'cultura',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg/1280px-Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg/1280px-Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg',
      'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  {
    id: 'att_igrejinha_carneiros',
    title: 'Capela de São Benedito (Igrejinha)',
    subtitle: 'Praia dos Carneiros • Capela do Século XVIII à Beira-Mar',
    uf: 'PE',
    citySlug: 'carneiros',
    category: 'cultura',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg/1280px-Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg/1280px-Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg',
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  {
    id: 'att_baia_do_sancho',
    title: 'Baía do Sancho',
    subtitle: 'Fernando de Noronha • Eleita a Melhor Praia do Mundo',
    uf: 'PE',
    citySlug: 'noronha',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Morro_Dois_Irm%C3%A3os_em_Fernando_de_Noronha%2C_Pernambuco.jpg/1280px-Morro_Dois_Irm%C3%A3os_em_Fernando_de_Noronha%2C_Pernambuco.jpg',
    ],
  },
  {
    id: 'att_muro_alto',
    title: 'Praia de Muro Alto',
    subtitle: 'Porto de Galinhas • Piscina Natural de 3km Sem Ondas',
    uf: 'PE',
    citySlug: 'porto_de_galinhas',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg/1280px-BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg/1280px-BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg',
    ],
  },
  {
    id: 'att_pontal_maracaipe',
    title: 'Pontal de Maracaípe',
    subtitle: 'Porto de Galinhas • Encontro do Rio com o Mar e Mangue',
    uf: 'PE',
    citySlug: 'porto_de_galinhas',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg/1280px-BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg/1280px-BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg/1280px-BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg',
    ],
  },
  {
    id: 'att_cais_do_sertao',
    title: 'Museu Cais do Sertão',
    subtitle: 'Recife • Cultura Sertaneja, Luiz Gonzaga e Interatividade',
    uf: 'PE',
    citySlug: 'recife',
    category: 'cultura',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg/1280px-BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg/1280px-BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg',
      'https://images.unsplash.com/photo-1582650625119-3a31f8418365?auto=format&fit=crop&w=1200&q=80',
    ],
  },

  // --- ALAGOAS: ATRAÇÕES ---
  {
    id: 'att_piscinas_pajucara',
    title: 'Piscinas Naturais da Pajuçara',
    subtitle: 'Maceió • Passeio de Jangada Tradicional até os Corais',
    uf: 'AL',
    citySlug: 'maceio',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Orla_de_Macei%C3%B3_2023.jpg/1280px-Orla_de_Macei%C3%B3_2023.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Orla_de_Macei%C3%B3_2023.jpg/1280px-Orla_de_Macei%C3%B3_2023.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg/1280px-Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg',
    ],
  },
  {
    id: 'att_farol_ponta_verde',
    title: 'Farol da Ponta Verde',
    subtitle: 'Maceió • Caminhada sobre os Recifes na Maré Baixa',
    uf: 'AL',
    citySlug: 'maceio',
    category: 'cultura',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg/1280px-Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg/1280px-Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Orla_de_Macei%C3%B3_2023.jpg/1280px-Orla_de_Macei%C3%B3_2023.jpg',
    ],
  },
  {
    id: 'att_praia_do_frances',
    title: 'Praia do Francês',
    subtitle: 'Marechal Deodoro • Barreira de Corais e Área de Surf',
    uf: 'AL',
    citySlug: 'maceio',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Praia_do_Franc%C3%AAs%2C_Marechal_Deodoro_01.jpg/1280px-Praia_do_Franc%C3%AAs%2C_Marechal_Deodoro_01.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Praia_do_Franc%C3%AAs%2C_Marechal_Deodoro_01.jpg/1280px-Praia_do_Franc%C3%AAs%2C_Marechal_Deodoro_01.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG/1280px-Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG',
    ],
  },
  {
    id: 'att_gales_maragogi',
    title: 'Galés de Maragogi',
    subtitle: 'Maragogi • Aquário Natural em Alto-Mar com Águas Turquesas',
    uf: 'AL',
    citySlug: 'maragogi',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Maragogi_beach_tourist.jpg/1280px-Maragogi_beach_tourist.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Maragogi_beach_tourist.jpg/1280px-Maragogi_beach_tourist.jpg',
      'https://images.unsplash.com/photo-1515238152791-8216bfdf89a7?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  {
    id: 'att_praia_do_toque',
    title: 'Praia do Toque',
    subtitle: 'São Miguel dos Milagres • Mar de Esmeralda e Coqueirais Desertos',
    uf: 'AL',
    citySlug: 'milagres',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg/1280px-Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg/1280px-Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg',
      'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  {
    id: 'att_praia_ipioca',
    title: 'Praia de Ipioca & Hibiscus',
    subtitle: 'Maceió • Litoral Norte com Mar Turquesa e Beach Clubs',
    uf: 'AL',
    citySlug: 'maceio',
    category: 'praia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG/1280px-Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG/1280px-Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg/1280px-Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg',
    ],
  },
  {
    id: 'att_massagueira_gastronomia',
    title: 'Polo Gastronômico da Massagueira',
    subtitle: 'Marechal Deodoro • Frutos do Mar e Doces à Beira da Lagoa',
    uf: 'AL',
    citySlug: 'maceio',
    category: 'gastronomia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
    sourceType: 'curated',
    curatedSuggestions: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
    ],
  },

  // --- BANNERS HOUSE ADS ---
  {
    id: 'ad_banner_carneiros',
    title: 'Passeio de Catamarã em Carneiros',
    subtitle: 'House Ad Banner • Rota dos Recifes e Banho de Argila',
    uf: 'PE',
    category: 'anuncio',
    imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
    sourceType: 'campanha',
  },
  {
    id: 'ad_banner_maragogi',
    title: 'Lancha Exclusiva nas Galés de Maragogi',
    subtitle: 'House Ad Banner • Passeios VIP para Piscinas Naturais',
    uf: 'AL',
    category: 'anuncio',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Maragogi_beach_tourist.jpg/1280px-Maragogi_beach_tourist.jpg',
    sourceType: 'campanha',
  },
  {
    id: 'push_banner_welcome',
    title: 'Banner de Notificações One Tour',
    subtitle: 'Push Broadcast • Boas-vindas e Destaques do Dia',
    uf: 'ALL',
    category: 'push',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    sourceType: 'push',
  },
];

export const ImagesTab: React.FC<ImagesTabProps> = ({
  cities,
  attractions,
  selectedUf,
  onRefresh,
  isLoading,
  onNotify,
  isAuthenticated,
  onOpenLogin,
}) => {
  // Stored overrides in localStorage
  const [overrides, setOverrides] = useState<Record<string, string>>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      return saved ? JSON.parse(saved) : {};
    } catch {
      return {};
    }
  });

  // Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [ufFilter, setUfFilter] = useState<string>('all');

  // Edit Modal State
  const [editingItem, setEditingItem] = useState<AppImageItem | null>(null);
  const [newImageUrl, setNewImageUrl] = useState('');
  const [isUploading, setIsUploading] = useState(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  // Lightbox Preview Modal State
  const [previewItem, setPreviewItem] = useState<AppImageItem | null>(null);

  // Combine default items with PocketBase dynamic data and user overrides
  const allImages = useMemo(() => {
    const list: AppImageItem[] = [...DEFAULT_APP_IMAGES];

    // Merge PocketBase cities that might not be in default catalog
    cities.forEach((c) => {
      const existing = list.find((item) => item.id === `cidade_${c.slug}`);
      if (existing) {
        if ((c as any).imagem || (c as any).image_url) {
          existing.imageUrl = (c as any).imagem || (c as any).image_url;
          existing.sourceType = 'cidade';
          existing.sourceId = c.id;
        }
      } else {
        list.push({
          id: `cidade_${c.slug}`,
          title: c.nome,
          subtitle: `${c.tag || 'Destino Turístico'} • PocketBase Record`,
          uf: c.estado_sigla || 'PE',
          citySlug: c.slug,
          category: 'cidade',
          imageUrl:
            (c as any).imagem ||
            (c as any).image_url ||
            'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
          sourceType: 'cidade',
          sourceId: c.id,
        });
      }
    });

    // Merge PocketBase attractions
    attractions.forEach((a) => {
      const existing = list.find((item) => item.id === `att_${a.slug}`);
      if (existing) {
        if ((a as any).imagem || (a as any).image_url) {
          existing.imageUrl = (a as any).imagem || (a as any).image_url;
          existing.sourceType = 'atracao';
          existing.sourceId = a.id;
        }
      }
    });

    // Apply local storage overrides
    return list.map((item) => {
      if (overrides[item.id]) {
        return {
          ...item,
          imageUrl: overrides[item.id],
        };
      }
      return item;
    });
  }, [cities, attractions, overrides]);

  // Filtered images
  const filteredImages = useMemo(() => {
    return allImages.filter((item) => {
      // UF Filter
      const targetUf = ufFilter === 'all' ? selectedUf : ufFilter;
      const matchUf = targetUf === 'ALL' || item.uf === 'ALL' || item.uf === targetUf;

      // Category Filter
      const matchCat = categoryFilter === 'all' || item.category === categoryFilter;

      // Search term
      const term = searchTerm.toLowerCase().trim();
      const matchSearch =
        !term ||
        item.title.toLowerCase().includes(term) ||
        item.subtitle.toLowerCase().includes(term) ||
        (item.citySlug && item.citySlug.toLowerCase().includes(term)) ||
        item.uf.toLowerCase().includes(term);

      return matchUf && matchCat && matchSearch;
    });
  }, [allImages, ufFilter, selectedUf, categoryFilter, searchTerm]);

  // Open edit modal
  const handleOpenEdit = (item: AppImageItem) => {
    setEditingItem(item);
    setNewImageUrl(item.imageUrl);
  };

  // Close edit modal
  const handleCloseEdit = () => {
    setEditingItem(null);
    setNewImageUrl('');
    setIsUploading(false);
  };

  // Upload local file
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      onNotify('Por favor, selecione um arquivo de imagem válido (PNG, JPG, WebP).', 'error');
      return;
    }

    if (file.size > 8 * 1024 * 1024) {
      onNotify('O arquivo excede o limite máximo permitido de 8MB.', 'error');
      return;
    }

    setIsUploading(true);
    try {
      const res = await uploadAdImage(file);
      setNewImageUrl(res.url);
      onNotify(`Upload concluído com sucesso! Tamanho: ${(res.sizeBytes / 1024).toFixed(0)} KB`);
    } catch (err: any) {
      onNotify(`Erro ao fazer upload da imagem: ${err.message}`, 'error');
    } finally {
      setIsUploading(false);
    }
  };

  // Save changes
  const handleSave = async () => {
    if (!editingItem) return;

    const trimmedUrl = newImageUrl.trim();
    if (!trimmedUrl) {
      onNotify('Informe uma URL de imagem válida.', 'error');
      return;
    }

    // 1. Save in local state and localStorage
    const nextOverrides = { ...overrides, [editingItem.id]: trimmedUrl };
    setOverrides(nextOverrides);
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(nextOverrides));
    } catch (e) {
      console.warn('Failed to save to localStorage:', e);
    }

    // 2. If it's a PocketBase item and user is authenticated, attempt remote sync
    if (editingItem.sourceId && !isAuthenticated) {
      onOpenLogin();
    }
    if (editingItem.sourceId && isAuthenticated) {
      try {
        const collection = editingItem.sourceType === 'cidade' ? 'cidades' : 'atracoes';
        await updatePbRecord(collection, editingItem.sourceId, {
          image_url: trimmedUrl,
          imagem: trimmedUrl,
        });
        onNotify(`Foto de "${editingItem.title}" salva no PocketBase e aplicada com sucesso!`);
      } catch (err: any) {
        onNotify(`Salvo localmente! PocketBase remoto não aceitou PATCH: ${err.message}`, 'error');
      }
    } else {
      onNotify(`Imagem de "${editingItem.title}" atualizada com sucesso no app!`);
    }

    handleCloseEdit();
  };

  // Reset to default authentic photo
  const handleResetToDefault = (item: AppImageItem) => {
    const nextOverrides = { ...overrides };
    delete nextOverrides[item.id];
    setOverrides(nextOverrides);
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(nextOverrides));
    } catch {}
    onNotify(`Foto de "${item.title}" restaurada para a original verificada!`);
    if (editingItem?.id === item.id) {
      const defaultItem = DEFAULT_APP_IMAGES.find((d) => d.id === item.id);
      if (defaultItem) setNewImageUrl(defaultItem.imageUrl);
    }
  };

  // Copy URL to clipboard
  const handleCopyUrl = (url: string, id: string) => {
    navigator.clipboard.writeText(url);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2500);
    onNotify('URL da imagem copiada para a área de transferência!');
  };

  // Export JSON mapping
  const handleExportJson = () => {
    const mapping = allImages.map((img) => ({
      id: img.id,
      title: img.title,
      uf: img.uf,
      category: img.category,
      imageUrl: img.imageUrl,
    }));
    const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(mapping, null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute('href', dataStr);
    downloadAnchor.setAttribute('download', `onetour_app_images_${selectedUf}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
    onNotify('Mapeamento de fotos exportado com sucesso em JSON!');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* Header Panel */}
      <div
        className="glass-panel"
        style={{
          padding: '24px 28px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 16,
          background: 'linear-gradient(135deg, rgba(17, 24, 39, 0.85) 0%, rgba(30, 41, 59, 0.7) 100%)',
          borderLeft: '4px solid var(--accent-cyan)',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
            <span
              className="badge"
              style={{
                background: 'rgba(6, 182, 212, 0.15)',
                color: '#38bdf8',
                border: '1px solid rgba(56, 189, 248, 0.3)',
                fontWeight: 700,
              }}
            >
              GESTÃO MULTI-FLAVOR
            </span>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              Fotos Reais de Cidades, Praias e Atrações • {filteredImages.length} Itens Catalogados
            </span>
          </div>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, letterSpacing: '-0.02em' }}>
            Galeria & Editor de Imagens dos Apps
          </h1>
          <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: 4, maxWidth: 780 }}>
            Gerencie todas as fotos exibidas no One Tour Pernambuco, One Tour Alagoas e demais estados.
            Faça upload de novas imagens ou selecione fotos autênticas verificadas para cada ponto turístico.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          <button onClick={handleExportJson} className="btn btn-secondary" title="Exportar mapeamento de fotos em JSON">
            <Download size={15} />
            <span>Exportar JSON</span>
          </button>
          <button onClick={onRefresh} disabled={isLoading} className="btn btn-primary" title="Sincronizar com PocketBase">
            <RefreshCw size={15} className={isLoading ? 'spin' : ''} />
            <span>Sincronizar</span>
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div
        className="glass-panel"
        style={{
          padding: '16px 20px',
          display: 'flex',
          gap: 16,
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        {/* Search */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: '1 1 280px', position: 'relative' }}>
          <Search size={16} style={{ color: 'var(--text-muted)', position: 'absolute', left: 12 }} />
          <input
            type="text"
            className="input-field"
            style={{ paddingLeft: 38 }}
            placeholder="Buscar por lugar, praia, cidade ou estado..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
          {searchTerm && (
            <button
              onClick={() => setSearchTerm('')}
              style={{
                position: 'absolute',
                right: 12,
                background: 'transparent',
                border: 'none',
                color: 'var(--text-dim)',
                cursor: 'pointer',
              }}
            >
              <X size={14} />
            </button>
          )}
        </div>

        {/* Filters */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
          {/* UF Filter */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>UF:</span>
            <select
              value={ufFilter}
              onChange={(e) => setUfFilter(e.target.value)}
              className="select-field"
              style={{ padding: '6px 12px', fontSize: '0.82rem' }}
            >
              <option value="all">Todas as UFs</option>
              <option value="PE">Pernambuco (PE)</option>
              <option value="AL">Alagoas (AL)</option>
              <option value="PB">Paraíba (PB)</option>
              <option value="ALL">Geral / Multi-Estado</option>
            </select>
          </div>

          {/* Category Filter */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>Categoria:</span>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="select-field"
              style={{ padding: '6px 12px', fontSize: '0.82rem' }}
            >
              <option value="all">Todas as Categorias</option>
              <option value="cidade">Cidades & Destinos</option>
              <option value="praia">Praias & Litoral</option>
              <option value="cultura">Cultura & História</option>
              <option value="gastronomia">Gastronomia</option>
              <option value="anuncio">House Ads & Banners</option>
              <option value="push">Notificações Push</option>
            </select>
          </div>
        </div>
      </div>

      {/* Image Cards Grid */}
      {filteredImages.length === 0 ? (
        <div
          className="glass-panel"
          style={{
            padding: '48px 24px',
            textAlign: 'center',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 12,
          }}
        >
          <ImageIcon size={42} style={{ color: 'var(--text-dim)', opacity: 0.5 }} />
          <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Nenhuma imagem encontrada</h3>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', maxWidth: 420 }}>
            Tente ajustar os filtros territoriais ou o termo de busca para visualizar as fotos dos destinos.
          </p>
        </div>
      ) : (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
            gap: 20,
          }}
        >
          {filteredImages.map((item) => {
            const isCustom = !!overrides[item.id];
            const isCopied = copiedId === item.id;

            return (
              <div
                key={item.id}
                className="glass-panel"
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  overflow: 'hidden',
                  borderRadius: 'var(--radius-md)',
                  transition: 'transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease',
                  border: isCustom ? '1px solid rgba(56, 189, 248, 0.4)' : '1px solid var(--border-subtle)',
                }}
              >
                {/* Image Thumbnail Container */}
                <div
                  style={{
                    position: 'relative',
                    width: '100%',
                    height: 190,
                    background: '#0d1322',
                    overflow: 'hidden',
                  }}
                >
                  <img
                    src={item.imageUrl}
                    alt={item.title}
                    loading="lazy"
                    style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover',
                      transition: 'transform 0.3s ease',
                    }}
                    onError={(e) => {
                      (e.target as HTMLImageElement).src =
                        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80';
                    }}
                  />

                  {/* Gradient Overlay */}
                  <div
                    style={{
                      position: 'absolute',
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      background: 'linear-gradient(to top, rgba(9, 13, 22, 0.85) 0%, transparent 60%)',
                    }}
                  />

                  {/* Top Badges */}
                  <div
                    style={{
                      position: 'absolute',
                      top: 10,
                      left: 10,
                      display: 'flex',
                      gap: 6,
                      alignItems: 'center',
                    }}
                  >
                    <span
                      style={{
                        fontSize: '0.72rem',
                        fontWeight: 800,
                        padding: '3px 8px',
                        borderRadius: 'var(--radius-full)',
                        background:
                          item.uf === 'PE'
                            ? 'rgba(59, 130, 246, 0.9)'
                            : item.uf === 'AL'
                            ? 'rgba(16, 185, 129, 0.9)'
                            : 'rgba(139, 92, 246, 0.9)',
                        color: 'white',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.4)',
                      }}
                    >
                      {item.uf}
                    </span>

                    <span
                      style={{
                        fontSize: '0.68rem',
                        fontWeight: 700,
                        padding: '3px 8px',
                        borderRadius: 'var(--radius-full)',
                        background: 'rgba(0, 0, 0, 0.65)',
                        backdropFilter: 'blur(8px)',
                        color: 'var(--text-main)',
                        border: '1px solid rgba(255,255,255,0.1)',
                        textTransform: 'uppercase',
                      }}
                    >
                      {item.category}
                    </span>
                  </div>

                  {/* Custom Indicator Badge */}
                  {isCustom && (
                    <div
                      style={{
                        position: 'absolute',
                        top: 10,
                        right: 10,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 4,
                        fontSize: '0.65rem',
                        fontWeight: 800,
                        padding: '3px 8px',
                        borderRadius: 'var(--radius-full)',
                        background: 'rgba(6, 182, 212, 0.95)',
                        color: '#082f49',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.5)',
                      }}
                    >
                      <Sparkles size={11} />
                      <span>EDITADA</span>
                    </div>
                  )}

                  {/* Zoom Preview Button */}
                  <button
                    onClick={() => setPreviewItem(item)}
                    title="Ampliar foto"
                    style={{
                      position: 'absolute',
                      bottom: 10,
                      right: 10,
                      background: 'rgba(0, 0, 0, 0.65)',
                      border: '1px solid rgba(255, 255, 255, 0.2)',
                      color: 'white',
                      borderRadius: 'var(--radius-full)',
                      width: 32,
                      height: 32,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      backdropFilter: 'blur(8px)',
                      transition: 'all 0.15s ease',
                    }}
                  >
                    <Eye size={15} />
                  </button>
                </div>

                {/* Content Body */}
                <div style={{ padding: '16px 18px', display: 'flex', flexDirection: 'column', flex: 1, gap: 10 }}>
                  <div>
                    <h3
                      style={{
                        fontSize: '1.02rem',
                        fontWeight: 700,
                        color: 'var(--text-main)',
                        lineHeight: 1.3,
                      }}
                    >
                      {item.title}
                    </h3>
                    <p
                      style={{
                        fontSize: '0.78rem',
                        color: 'var(--text-muted)',
                        marginTop: 4,
                        lineHeight: 1.4,
                      }}
                    >
                      {item.subtitle}
                    </p>
                  </div>

                  {/* Current URL preview */}
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 8,
                      background: 'rgba(0, 0, 0, 0.3)',
                      padding: '6px 10px',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid rgba(255, 255, 255, 0.05)',
                    }}
                  >
                    <LinkIcon size={12} style={{ color: 'var(--text-dim)', flexShrink: 0 }} />
                    <span
                      style={{
                        fontSize: '0.72rem',
                        color: 'var(--text-dim)',
                        fontFamily: 'monospace',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        flex: 1,
                      }}
                    >
                      {item.imageUrl}
                    </span>
                    <button
                      onClick={() => handleCopyUrl(item.imageUrl, item.id)}
                      title="Copiar URL"
                      style={{
                        background: 'transparent',
                        border: 'none',
                        color: isCopied ? 'var(--accent-green)' : 'var(--text-muted)',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        flexShrink: 0,
                      }}
                    >
                      {isCopied ? <Check size={14} /> : <Copy size={13} />}
                    </button>
                  </div>

                  {/* Actions Footer */}
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      marginTop: 'auto',
                      paddingTop: 10,
                      borderTop: '1px solid rgba(255, 255, 255, 0.06)',
                      gap: 8,
                    }}
                  >
                    {isCustom ? (
                      <button
                        onClick={() => handleResetToDefault(item)}
                        style={{
                          background: 'transparent',
                          border: 'none',
                          color: 'var(--text-dim)',
                          fontSize: '0.75rem',
                          cursor: 'pointer',
                          textDecoration: 'underline',
                        }}
                      >
                        Restaurar original
                      </button>
                    ) : (
                      <span style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>Foto Oficial</span>
                    )}

                    <button
                      onClick={() => handleOpenEdit(item)}
                      className="btn btn-primary"
                      style={{ padding: '6px 14px', fontSize: '0.8rem' }}
                    >
                      <Edit3 size={13} />
                      <span>Editar Imagem</span>
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Edit Image Modal */}
      {editingItem && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0, 0, 0, 0.78)',
            backdropFilter: 'blur(12px)',
            zIndex: 1000,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 20,
          }}
        >
          <div
            className="glass-panel"
            style={{
              maxWidth: 620,
              width: '100%',
              maxHeight: '90vh',
              overflowY: 'auto',
              padding: '28px',
              display: 'flex',
              flexDirection: 'column',
              gap: 20,
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.7)',
              border: '1px solid rgba(99, 102, 241, 0.3)',
            }}
          >
            {/* Modal Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                  <span className="badge badge-primary">{editingItem.uf}</span>
                  <span className="badge badge-info">{editingItem.category.toUpperCase()}</span>
                </div>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Editar Foto: {editingItem.title}</h2>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{editingItem.subtitle}</p>
              </div>
              <button
                onClick={handleCloseEdit}
                style={{
                  background: 'rgba(255, 255, 255, 0.05)',
                  border: 'none',
                  color: 'var(--text-muted)',
                  borderRadius: 'var(--radius-full)',
                  width: 32,
                  height: 32,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                }}
              >
                <X size={16} />
              </button>
            </div>

            {/* Live Preview Side-by-Side or Large Preview */}
            <div>
              <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', display: 'block', marginBottom: 6 }}>
                PRÉ-VISUALIZAÇÃO DA NOVA IMAGEM:
              </span>
              <div
                style={{
                  width: '100%',
                  height: 220,
                  borderRadius: 'var(--radius-sm)',
                  overflow: 'hidden',
                  background: '#090d16',
                  border: '1px solid var(--border-subtle)',
                  position: 'relative',
                }}
              >
                {newImageUrl ? (
                  <img
                    src={newImageUrl}
                    alt="Preview"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    onError={(e) => {
                      (e.target as HTMLImageElement).src =
                        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80';
                    }}
                  />
                ) : (
                  <div
                    style={{
                      height: '100%',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: 'var(--text-dim)',
                    }}
                  >
                    <ImageIcon size={32} />
                    <span style={{ fontSize: '0.8rem', marginTop: 8 }}>Nenhuma imagem informada</span>
                  </div>
                )}
              </div>
            </div>

            {/* Edit Options Tabs / Sections */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              {/* Option 1: File Upload */}
              <div
                style={{
                  border: '1px dashed rgba(99, 102, 241, 0.4)',
                  padding: '16px',
                  borderRadius: 'var(--radius-sm)',
                  background: 'rgba(99, 102, 241, 0.04)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: 16,
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <div
                    style={{
                      width: 36,
                      height: 36,
                      borderRadius: 8,
                      background: 'rgba(99, 102, 241, 0.2)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: '#818cf8',
                    }}
                  >
                    <Upload size={18} />
                  </div>
                  <div>
                    <div style={{ fontSize: '0.85rem', fontWeight: 700 }}>Fazer Upload de Foto do Computador</div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                      PNG, JPG ou WebP de alta resolução (máx. 8MB)
                    </div>
                  </div>
                </div>

                <label
                  className={`btn ${isUploading ? 'btn-secondary' : 'btn-primary'}`}
                  style={{ cursor: isUploading ? 'not-allowed' : 'pointer', fontSize: '0.8rem', padding: '6px 14px' }}
                >
                  {isUploading ? (
                    <>
                      <RefreshCw size={13} className="spin" />
                      <span>Enviando...</span>
                    </>
                  ) : (
                    <>
                      <Upload size={13} />
                      <span>Selecionar Arquivo</span>
                    </>
                  )}
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleFileUpload}
                    disabled={isUploading}
                    style={{ display: 'none' }}
                  />
                </label>
              </div>

              {/* Option 2: Direct URL Input */}
              <div>
                <label
                  style={{
                    display: 'block',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    color: 'var(--text-muted)',
                    marginBottom: 6,
                  }}
                >
                  OU DIGITE / COLE A URL DA IMAGEM:
                </label>
                <input
                  type="text"
                  className="input-field"
                  placeholder="https://images.unsplash.com/... ou URL do seu servidor CDN"
                  value={newImageUrl}
                  onChange={(e) => setNewImageUrl(e.target.value)}
                />
              </div>

              {/* Option 3: Curated Suggestions for this spot */}
              {editingItem.curatedSuggestions && editingItem.curatedSuggestions.length > 0 && (
                <div>
                  <span
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                      fontSize: '0.75rem',
                      fontWeight: 700,
                      color: 'var(--accent-cyan)',
                      marginBottom: 8,
                    }}
                  >
                    <Sparkles size={13} />
                    <span>FOTOS REAIS SUGERIDAS PARA ESTE LOCAL (1 CLIQUE):</span>
                  </span>

                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
                    {editingItem.curatedSuggestions.map((suggestionUrl, index) => {
                      const isSelected = newImageUrl === suggestionUrl;
                      return (
                        <div
                          key={index}
                          onClick={() => setNewImageUrl(suggestionUrl)}
                          style={{
                            height: 70,
                            borderRadius: 'var(--radius-sm)',
                            overflow: 'hidden',
                            cursor: 'pointer',
                            position: 'relative',
                            border: isSelected ? '2px solid #38bdf8' : '1px solid rgba(255, 255, 255, 0.1)',
                            boxShadow: isSelected ? '0 0 12px rgba(56, 189, 248, 0.4)' : 'none',
                          }}
                        >
                          <img
                            src={suggestionUrl}
                            alt={`Sugestão ${index + 1}`}
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                          />
                          {isSelected && (
                            <div
                              style={{
                                position: 'absolute',
                                top: 4,
                                right: 4,
                                background: '#38bdf8',
                                color: '#090d16',
                                borderRadius: 'var(--radius-full)',
                                width: 18,
                                height: 18,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                              }}
                            >
                              <Check size={12} strokeWidth={3} />
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>

            {/* Modal Actions */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'flex-end',
                gap: 12,
                marginTop: 10,
                paddingTop: 16,
                borderTop: '1px solid var(--border-subtle)',
              }}
            >
              <button onClick={handleCloseEdit} className="btn btn-secondary">
                Cancelar
              </button>
              <button onClick={handleSave} className="btn btn-primary" style={{ padding: '8px 22px' }}>
                <Check size={15} />
                <span>Salvar Imagem</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Lightbox / Zoom Preview Modal */}
      {previewItem && (
        <div
          onClick={() => setPreviewItem(null)}
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0, 0, 0, 0.88)',
            backdropFilter: 'blur(16px)',
            zIndex: 1200,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 24,
            cursor: 'zoom-out',
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              maxWidth: 960,
              width: '100%',
              display: 'flex',
              flexDirection: 'column',
              gap: 12,
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: 'white' }}>
              <div>
                <span className="badge badge-primary" style={{ marginRight: 8 }}>
                  {previewItem.uf}
                </span>
                <span style={{ fontWeight: 700, fontSize: '1.1rem' }}>{previewItem.title}</span>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginLeft: 8 }}>
                  • {previewItem.subtitle}
                </span>
              </div>
              <button
                onClick={() => setPreviewItem(null)}
                className="btn btn-secondary"
                style={{ padding: '6px 10px', borderRadius: 'var(--radius-full)' }}
              >
                <X size={18} />
              </button>
            </div>

            <div
              style={{
                width: '100%',
                maxHeight: '75vh',
                borderRadius: 'var(--radius-md)',
                overflow: 'hidden',
                background: '#090d16',
                boxShadow: '0 25px 60px rgba(0, 0, 0, 0.8)',
              }}
            >
              <img
                src={previewItem.imageUrl}
                alt={previewItem.title}
                style={{ width: '100%', height: '100%', objectFit: 'contain' }}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
