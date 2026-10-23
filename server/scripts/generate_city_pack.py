#!/usr/bin/env python3
"""
One Tour - City Pack SQLite Generator (ETL)
Generates standalone, offline-first city packs (pack.sqlite) containing POIs
and precomputed distance/time travel matrices for the local VRP trip planner.

Phase 6: Multi-city support for Pernambuco (Recife, Porto de Galinhas, Praia dos Carneiros, Fernando de Noronha).
"""

import sys
import os
import math
import sqlite3
import argparse
from datetime import datetime, timezone

# Haversine distance calculator
def haversine_meters(lat1, lon1, lat2, lon2):
    R = 6371000  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (math.sin(delta_phi / 2.0) ** 2 +
         math.cos(phi1) * math.cos(phi2) * (math.sin(delta_lambda / 2.0) ** 2))
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return int(R * c)

# Realistic travel time estimations
def estimate_travel_times(meters):
    # Walk: 4.5 km/h = 1.25 m/s + 120s buffer
    walk_sec = int(meters / 1.25) + 120 if meters <= 2500 else 99999
    # Drive: 25 km/h urban = 6.94 m/s + 300s buffer (traffic/parking)
    drive_sec = int(meters / 6.94) + 300
    return walk_sec, drive_sec

# 1. RECIFE & OLINDA (Capital Multicultural)
RECIFE_PLACES = [
    {
        "id": "marco_zero",
        "city_slug": "recife",
        "name": "Praça do Marco Zero",
        "category": "cultura",
        "lat": -8.0631,
        "lon": -34.8711,
        "duration_min": 75,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 98.5,
        "rating_avg": 4.9,
        "rating_count": 4820,
        "likes_count": 9150,
        "rank_posicao": 1,
        "description": "Coração do Recife Antigo, marco geográfico e vista panorâmica para o Parque das Esculturas no mar.",
        "image_url": "https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?auto=format&fit=crop&w=800&q=80",
        "opening_time": "00:00",
        "closing_time": "23:59"
    },
    {
        "id": "cais_do_sertao",
        "city_slug": "recife",
        "name": "Museu Cais do Sertão",
        "category": "cultura",
        "lat": -8.0608,
        "lon": -34.8706,
        "duration_min": 90,
        "cost_level": 2,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 96.0,
        "rating_avg": 4.8,
        "rating_count": 3120,
        "likes_count": 6400,
        "rank_posicao": 2,
        "description": "Museu interativo e sensorial dedicado à cultura do sertão nordestino e a Luiz Gonzaga.",
        "image_url": "https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "17:00"
    },
    {
        "id": "paco_do_frevo",
        "city_slug": "recife",
        "name": "Paço do Frevo",
        "category": "cultura",
        "lat": -8.0620,
        "lon": -34.8718,
        "duration_min": 60,
        "cost_level": 2,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 94.5,
        "rating_avg": 4.8,
        "rating_count": 2780,
        "likes_count": 5200,
        "rank_posicao": 3,
        "description": "Espaço dedicado à salvaguarda e celebração do Frevo, Patrimônio Imaterial da Humanidade pela UNESCO.",
        "image_url": "https://images.unsplash.com/photo-1582650625119-3a31f8418b7d?auto=format&fit=crop&w=800&q=80",
        "opening_time": "10:00",
        "closing_time": "17:00"
    },
    {
        "id": "rua_do_bom_jesus",
        "city_slug": "recife",
        "name": "Rua do Bom Jesus & Sinagoga Kahal Zur Israel",
        "category": "cultura",
        "lat": -8.0617,
        "lon": -34.8713,
        "duration_min": 60,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 97.0,
        "rating_avg": 4.9,
        "rating_count": 3950,
        "likes_count": 7890,
        "rank_posicao": 4,
        "description": "Eleita uma das ruas mais bonitas do mundo; abriga a primeira sinagoga das Américas (século XVII).",
        "image_url": "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "18:00"
    },
    {
        "id": "restaurante_leite",
        "city_slug": "recife",
        "name": "Restaurante Leite (Desde 1882)",
        "category": "gastronomia",
        "lat": -8.0612,
        "lon": -34.8835,
        "duration_min": 75,
        "cost_level": 4,
        "kid_friendly": 0,
        "must_see": 1,
        "is_lunch": 1,
        "score": 95.0,
        "rating_avg": 4.8,
        "rating_count": 2100,
        "likes_count": 4120,
        "rank_posicao": 5,
        "description": "O restaurante mais antigo em funcionamento contínuo do Brasil, famoso pelo Bacalhau e Cartola clássica.",
        "image_url": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
        "opening_time": "11:30",
        "closing_time": "16:00"
    },
    {
        "id": "parraxaxa_boa_viagem",
        "city_slug": "recife",
        "name": "Restaurante Parraxaxá",
        "category": "gastronomia",
        "lat": -8.1189,
        "lon": -34.9015,
        "duration_min": 70,
        "cost_level": 3,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 1,
        "score": 97.5,
        "rating_avg": 4.9,
        "rating_count": 5200,
        "likes_count": 8900,
        "rank_posicao": 6,
        "description": "Banquete autêntico de comida regional nordestina com carne de sol na nata, baião de dois e doces caseiros.",
        "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80",
        "opening_time": "11:30",
        "closing_time": "22:00"
    },
    {
        "id": "instituto_ricardo_brennand",
        "city_slug": "recife",
        "name": "Instituto Ricardo Brennand (Castelo)",
        "category": "cultura",
        "lat": -8.0645,
        "lon": -34.9642,
        "duration_min": 150,
        "cost_level": 3,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 99.0,
        "rating_avg": 4.9,
        "rating_count": 6800,
        "likes_count": 12500,
        "rank_posicao": 7,
        "description": "Castelo medieval cercado por reserva de Mata Atlântica; maior acervo do pintor Frans Post e armas brancas.",
        "image_url": "https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80",
        "opening_time": "13:00",
        "closing_time": "17:00"
    },
    {
        "id": "oficina_francisco_brennand",
        "city_slug": "recife",
        "name": "Oficina Francisco Brennand",
        "category": "cultura",
        "lat": -8.0531,
        "lon": -34.9749,
        "duration_min": 120,
        "cost_level": 2,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 96.5,
        "rating_avg": 4.8,
        "rating_count": 3400,
        "likes_count": 6800,
        "rank_posicao": 8,
        "description": "Templo monumental de esculturas e cerâmicas a céu aberto criado pelo mestre Francisco Brennand.",
        "image_url": "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80",
        "opening_time": "10:00",
        "closing_time": "17:00"
    },
    {
        "id": "praia_boa_viagem",
        "city_slug": "recife",
        "name": "Praia de Boa Viagem & Calçadão",
        "category": "praias",
        "lat": -8.1275,
        "lon": -34.9011,
        "duration_min": 120,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 95.5,
        "rating_avg": 4.7,
        "rating_count": 8900,
        "likes_count": 14200,
        "rank_posicao": 9,
        "description": "Orla mais famosa do Recife com 8km de calçadão, quiosques com água de coco gelada e piscinas naturais na maré baixa.",
        "image_url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "opening_time": "06:00",
        "closing_time": "22:00"
    },
    {
        "id": "parque_das_esculturas",
        "city_slug": "recife",
        "name": "Parque das Esculturas Francisco Brennand",
        "category": "cultura",
        "lat": -8.0642,
        "lon": -34.8685,
        "duration_min": 60,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 0,
        "is_lunch": 0,
        "score": 90.0,
        "rating_avg": 4.6,
        "rating_count": 1850,
        "likes_count": 3100,
        "rank_posicao": 10,
        "description": "Acesso de catamarã ou barquinho a partir do Marco Zero; abriga a monumental Coluna de Cristal de 32 metros.",
        "image_url": "https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "17:00"
    },
    {
        "id": "alto_da_se_olinda",
        "city_slug": "recife",
        "name": "Alto da Sé & Mirante Histórico de Olinda",
        "category": "cultura",
        "lat": -8.0139,
        "lon": -34.8519,
        "duration_min": 90,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 98.0,
        "rating_avg": 4.9,
        "rating_count": 6400,
        "likes_count": 11800,
        "rank_posicao": 11,
        "description": "Mirante lendário com vista de 360° para Recife e Olinda, barracas de tapiocas tradicionais e feira de artesanato.",
        "image_url": "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "20:00"
    },
    {
        "id": "mosteiro_sao_bento",
        "city_slug": "recife",
        "name": "Mosteiro de São Bento de Olinda",
        "category": "cultura",
        "lat": -8.0189,
        "lon": -34.8547,
        "duration_min": 60,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 95.0,
        "rating_avg": 4.8,
        "rating_count": 2900,
        "likes_count": 5400,
        "rank_posicao": 12,
        "description": "Joia do barroco brasileiro com altar-mor folheado a ouro de valor histórico incalculável.",
        "image_url": "https://images.unsplash.com/photo-1548625361-1250325d7b68?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "17:00"
    },
    {
        "id": "oficina_do_sabor",
        "city_slug": "recife",
        "name": "Restaurante Oficina do Sabor (Chef César Santos)",
        "category": "gastronomia",
        "lat": -8.0163,
        "lon": -34.8524,
        "duration_min": 80,
        "cost_level": 4,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 1,
        "score": 96.0,
        "rating_avg": 4.9,
        "rating_count": 2300,
        "likes_count": 4900,
        "rank_posicao": 13,
        "description": "Gastronomia pernambucana de autor em Olinda; famosa moranga recheada com frutos do mar e queijo coalho.",
        "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80",
        "opening_time": "12:00",
        "closing_time": "23:00"
    },
    {
        "id": "mercado_sao_jose",
        "city_slug": "recife",
        "name": "Mercado de São José & Artesanato",
        "category": "compras",
        "lat": -8.0678,
        "lon": -34.8778,
        "duration_min": 60,
        "cost_level": 1,
        "kid_friendly": 0,
        "must_see": 0,
        "is_lunch": 0,
        "score": 88.0,
        "rating_avg": 4.5,
        "rating_count": 3100,
        "likes_count": 4200,
        "rank_posicao": 14,
        "description": "Mercado público de estrutura em ferro fundido de 1875; polo de artesanato em palha, renda e temperos.",
        "image_url": "https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "17:00"
    },
    {
        "id": "jardim_botanico_recife",
        "city_slug": "recife",
        "name": "Jardim Botânico do Recife",
        "category": "natureza",
        "lat": -8.0772,
        "lon": -34.9664,
        "duration_min": 90,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 0,
        "is_lunch": 0,
        "score": 92.0,
        "rating_avg": 4.7,
        "rating_count": 1950,
        "likes_count": 3800,
        "rank_posicao": 15,
        "description": "Trilhas ecológicas imersas em Mata Atlântica preservada, orquidário, cactário e jardins sensoriais.",
        "image_url": "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "15:30"
    }
]

# 2. PORTO DE GALINHAS (Piscinas Naturais & Sol)
PORTO_DE_GALINHAS_PLACES = [
    {
        "id": "piscinas_porto",
        "city_slug": "porto_de_galinhas",
        "name": "Piscinas Naturais de Porto de Galinhas",
        "category": "praias",
        "lat": -8.5042,
        "lon": -35.0028,
        "duration_min": 120,
        "cost_level": 2,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 99.0,
        "rating_avg": 4.9,
        "rating_count": 5400,
        "likes_count": 11200,
        "rank_posicao": 1,
        "description": "Passeio clássico de jangada até a barreira de corais com águas cristalinas repletas de peixes sargentinhos.",
        "image_url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "opening_time": "07:00",
        "closing_time": "17:00"
    },
    {
        "id": "muro_alto",
        "city_slug": "porto_de_galinhas",
        "name": "Praia de Muro Alto & Paredão de Recifes",
        "category": "praias",
        "lat": -8.4712,
        "lon": -34.9875,
        "duration_min": 150,
        "cost_level": 2,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 97.5,
        "rating_avg": 4.9,
        "rating_count": 4200,
        "likes_count": 9800,
        "rank_posicao": 2,
        "description": "Verdadeira piscina oceânica de águas mornas e calmas, ideal para famílias com crianças e passeios de caiaque.",
        "image_url": "https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=800&q=80",
        "opening_time": "06:00",
        "closing_time": "18:00"
    },
    {
        "id": "pontal_maracaipe",
        "city_slug": "porto_de_galinhas",
        "name": "Pontal de Maracaípe & Passeio dos Cavalos-Marinhos",
        "category": "natureza",
        "lat": -8.5350,
        "lon": -35.0180,
        "duration_min": 90,
        "cost_level": 2,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 96.0,
        "rating_avg": 4.8,
        "rating_count": 3600,
        "likes_count": 7800,
        "rank_posicao": 3,
        "description": "Encontro do rio com o mar com jangadeiros levando para avistar cavalos-marinhos no manguezal e lindo pôr do sol.",
        "image_url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "17:30"
    },
    {
        "id": "praia_cupe",
        "city_slug": "porto_de_galinhas",
        "name": "Praia do Cupe & Pontal do Cupe",
        "category": "praias",
        "lat": -8.4890,
        "lon": -34.9960,
        "duration_min": 90,
        "cost_level": 1,
        "kid_friendly": 0,
        "must_see": 0,
        "is_lunch": 0,
        "score": 92.0,
        "rating_avg": 4.7,
        "rating_count": 2400,
        "likes_count": 5100,
        "rank_posicao": 4,
        "description": "Extensa praia com trecho de ondas para surf e pontal com piscinas calmas protegidas por arrecifes.",
        "image_url": "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80",
        "opening_time": "06:00",
        "closing_time": "18:00"
    },
    {
        "id": "vila_porto",
        "city_slug": "porto_de_galinhas",
        "name": "Vila de Porto & Galinhas Artesanais",
        "category": "compras",
        "lat": -8.5060,
        "lon": -35.0050,
        "duration_min": 75,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 94.0,
        "rating_avg": 4.8,
        "rating_count": 4100,
        "likes_count": 8200,
        "rank_posicao": 5,
        "description": "Centro charmoso com calçadões de pedestres, artesanato típico com esculturas de galinhas coloridas e sorveterias.",
        "image_url": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "23:00"
    },
    {
        "id": "barcaxeira",
        "city_slug": "porto_de_galinhas",
        "name": "Restaurante Barcaxeira",
        "category": "gastronomia",
        "lat": -8.5055,
        "lon": -35.0042,
        "duration_min": 75,
        "cost_level": 3,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 1,
        "score": 96.5,
        "rating_avg": 4.9,
        "rating_count": 3800,
        "likes_count": 7900,
        "rank_posicao": 6,
        "description": "Parada gastronômica obrigatória famosa pelos pratos de macaxeira gratinada com camarão e carne de sol.",
        "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80",
        "opening_time": "12:00",
        "closing_time": "23:00"
    },
    {
        "id": "restaurante_domingos",
        "city_slug": "porto_de_galinhas",
        "name": "Restaurante Domingos",
        "category": "gastronomia",
        "lat": -8.5062,
        "lon": -35.0048,
        "duration_min": 80,
        "cost_level": 4,
        "kid_friendly": 0,
        "must_see": 1,
        "is_lunch": 1,
        "score": 95.0,
        "rating_avg": 4.8,
        "rating_count": 2200,
        "likes_count": 4500,
        "rank_posicao": 7,
        "description": "Ambiente sofisticado com música ao vivo e pratos refinados de lagosta grelhada e peixes nobres.",
        "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80",
        "opening_time": "12:00",
        "closing_time": "23:30"
    },
    {
        "id": "projeto_hippocampus",
        "city_slug": "porto_de_galinhas",
        "name": "Projeto Hippocampus (Conservação)",
        "category": "natureza",
        "lat": -8.5015,
        "lon": -35.0068,
        "duration_min": 45,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 0,
        "is_lunch": 0,
        "score": 91.5,
        "rating_avg": 4.7,
        "rating_count": 1800,
        "likes_count": 3400,
        "rank_posicao": 8,
        "description": "Centro educativo e de preservação ambiental com aquários dedicados à pesquisa e conservação dos cavalos-marinhos.",
        "image_url": "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "16:30"
    },
    {
        "id": "buggy_ponta_a_ponta",
        "city_slug": "porto_de_galinhas",
        "name": "Passeio de Buggy Ponta a Ponta",
        "category": "aventura",
        "lat": -8.5050,
        "lon": -35.0035,
        "duration_min": 180,
        "cost_level": 3,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 98.0,
        "rating_avg": 4.9,
        "rating_count": 4900,
        "likes_count": 10400,
        "rank_posicao": 9,
        "description": "Aventura clássica que percorre de Muro Alto ao Pontal de Maracaípe pelas areias e coqueirais.",
        "image_url": "https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "16:00"
    },
    {
        "id": "praia_serrambi",
        "city_slug": "porto_de_galinhas",
        "name": "Praia de Serrambi & Enseada Tranquila",
        "category": "praias",
        "lat": -8.5610,
        "lon": -35.0320,
        "duration_min": 120,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 0,
        "is_lunch": 0,
        "score": 91.0,
        "rating_avg": 4.6,
        "rating_count": 1950,
        "likes_count": 3800,
        "rank_posicao": 10,
        "description": "Refúgio costeiro de águas mornas, excelente para caminhadas e esportes náuticos.",
        "image_url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "opening_time": "06:00",
        "closing_time": "18:00"
    }
]

# 3. PRAIA DOS CARNEIROS (Paraíso dos Coqueirais)
CARNEIROS_PLACES = [
    {
        "id": "capela_sao_benedito",
        "city_slug": "carneiros",
        "name": "Capela de São Benedito (Igrejinha de Carneiros)",
        "category": "cultura",
        "lat": -8.7042,
        "lon": -35.0883,
        "duration_min": 60,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 99.0,
        "rating_avg": 4.9,
        "rating_count": 4800,
        "likes_count": 12300,
        "rank_posicao": 1,
        "description": "A capela mais fotografada do Brasil, construída no século XVIII entre coqueiros centenários à beira da maré.",
        "image_url": "https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=800&q=80",
        "opening_time": "06:00",
        "closing_time": "18:00"
    },
    {
        "id": "piscinas_carneiros",
        "city_slug": "carneiros",
        "name": "Piscinas Naturais de Carneiros",
        "category": "praias",
        "lat": -8.7070,
        "lon": -35.0850,
        "duration_min": 120,
        "cost_level": 2,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 98.0,
        "rating_avg": 4.9,
        "rating_count": 4100,
        "likes_count": 9600,
        "rank_posicao": 2,
        "description": "Mar esmeralda translúcido com barreiras de corais acessíveis a pé durante a maré baixa.",
        "image_url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "opening_time": "07:00",
        "closing_time": "17:00"
    },
    {
        "id": "banho_argila_guadalupe",
        "city_slug": "carneiros",
        "name": "Banho de Argila na Praia de Guadalupe",
        "category": "natureza",
        "lat": -8.6850,
        "lon": -35.0740,
        "duration_min": 60,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 93.0,
        "rating_avg": 4.7,
        "rating_count": 2900,
        "likes_count": 5800,
        "rank_posicao": 3,
        "description": "Parada tradicional dos passeios de barco para esfoliação com argila medicinal rica em minerais.",
        "image_url": "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "16:30"
    },
    {
        "id": "catamara_bancos_areia",
        "city_slug": "carneiros",
        "name": "Passeio de Catamarã pelos Bancos de Areia",
        "category": "aventura",
        "lat": -8.7010,
        "lon": -35.0860,
        "duration_min": 120,
        "cost_level": 3,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 96.5,
        "rating_avg": 4.8,
        "rating_count": 3500,
        "likes_count": 7900,
        "rank_posicao": 4,
        "description": "Navegação cênica pelo estuário do Rio Formoso e bancos de areia que emergem no meio do mar límpido.",
        "image_url": "https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "16:00"
    },
    {
        "id": "bora_bora_carneiros",
        "city_slug": "carneiros",
        "name": "Bora Bora Carneiros (Beach Club & Restaurante)",
        "category": "gastronomia",
        "lat": -8.7030,
        "lon": -35.0875,
        "duration_min": 90,
        "cost_level": 3,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 1,
        "score": 97.0,
        "rating_avg": 4.8,
        "rating_count": 5200,
        "likes_count": 10500,
        "rank_posicao": 5,
        "description": "Estrutura completa pé na areia com gazebos, petiscos de frutos do mar, drinks tropicais e acesso privilegiado à praia.",
        "image_url": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "17:00"
    },
    {
        "id": "beijupira_carneiros",
        "city_slug": "carneiros",
        "name": "Restaurante Beijupirá Carneiros",
        "category": "gastronomia",
        "lat": -8.6990,
        "lon": -35.0845,
        "duration_min": 80,
        "cost_level": 4,
        "kid_friendly": 0,
        "must_see": 1,
        "is_lunch": 1,
        "score": 95.5,
        "rating_avg": 4.8,
        "rating_count": 2600,
        "likes_count": 5400,
        "rank_posicao": 6,
        "description": "Gastronomia pernambucana de praia sofisticada misturando peixes frescos grelhados com frutas tropicais.",
        "image_url": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80",
        "opening_time": "11:30",
        "closing_time": "17:00"
    },
    {
        "id": "rio_formoso_manguezal",
        "city_slug": "carneiros",
        "name": "Estuário do Rio Formoso & Manguezais",
        "category": "natureza",
        "lat": -8.6920,
        "lon": -35.0930,
        "duration_min": 75,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 0,
        "is_lunch": 0,
        "score": 90.5,
        "rating_avg": 4.6,
        "rating_count": 1700,
        "likes_count": 3200,
        "rank_posicao": 7,
        "description": "Rico ecossistema costeiro com passeios de stand up paddle e observação da biodiversidade marinha.",
        "image_url": "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "17:00"
    },
    {
        "id": "praia_do_amor",
        "city_slug": "carneiros",
        "name": "Praia do Amor & Coqueiro Solitário",
        "category": "praias",
        "lat": -8.7180,
        "lon": -35.0990,
        "duration_min": 90,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 0,
        "is_lunch": 0,
        "score": 89.0,
        "rating_avg": 4.6,
        "rating_count": 1400,
        "likes_count": 2900,
        "rank_posicao": 8,
        "description": "Faixa tranquila e quase deserta de areia branca perfeita para descanso e fotos deslumbrantes.",
        "image_url": "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80",
        "opening_time": "06:00",
        "closing_time": "18:00"
    }
]

# 4. FERNANDO DE NORONHA (Santuário Ecológico)
NORONHA_PLACES = [
    {
        "id": "baia_do_sancho",
        "city_slug": "noronha",
        "name": "Baía do Sancho (Melhor Praia do Mundo)",
        "category": "praias",
        "lat": -3.8542,
        "lon": -32.4435,
        "duration_min": 180,
        "cost_level": 2,
        "kid_friendly": 0,
        "must_see": 1,
        "is_lunch": 0,
        "score": 99.8,
        "rating_avg": 5.0,
        "rating_count": 6200,
        "likes_count": 18500,
        "rank_posicao": 1,
        "description": "Eleita repetidamente a melhor praia do planeta pelo TripAdvisor; acesso por fenda na rocha e água cristalina.",
        "image_url": "https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "18:00"
    },
    {
        "id": "baia_dos_porcos",
        "city_slug": "noronha",
        "name": "Baía dos Porcos & Morro Dois Irmãos",
        "category": "praias",
        "lat": -3.8510,
        "lon": -32.4410,
        "duration_min": 120,
        "cost_level": 1,
        "kid_friendly": 0,
        "must_see": 1,
        "is_lunch": 0,
        "score": 99.0,
        "rating_avg": 4.9,
        "rating_count": 5100,
        "likes_count": 14200,
        "rank_posicao": 2,
        "description": "Cartão-postal mais famoso do arquipélago, com piscinas naturais de cor verde-esmeralda emolduradas pelos Dois Irmãos.",
        "image_url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "18:00"
    },
    {
        "id": "cacimba_do_padre",
        "city_slug": "noronha",
        "name": "Praia da Cacimba do Padre",
        "category": "praias",
        "lat": -3.8530,
        "lon": -32.4460,
        "duration_min": 90,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 96.5,
        "rating_avg": 4.8,
        "rating_count": 3900,
        "likes_count": 8900,
        "rank_posicao": 3,
        "description": "Meca do surf brasileiro com tubos perfeitos e ampla faixa de areia voltada para o Morro Dois Irmãos.",
        "image_url": "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80",
        "opening_time": "06:00",
        "closing_time": "18:30"
    },
    {
        "id": "mirante_golfinhos",
        "city_slug": "noronha",
        "name": "Mirante dos Golfinhos Rotadores",
        "category": "natureza",
        "lat": -3.8550,
        "lon": -32.4380,
        "duration_min": 90,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 97.0,
        "rating_avg": 4.9,
        "rating_count": 3400,
        "likes_count": 7600,
        "rank_posicao": 4,
        "description": "Ponto de observação no alto do paredão rochoso onde centenas de golfinhos rotadores se reúnem ao amanhecer.",
        "image_url": "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80",
        "opening_time": "06:30",
        "closing_time": "16:00"
    },
    {
        "id": "projeto_tamar_noronha",
        "city_slug": "noronha",
        "name": "Centro de Visitantes Projeto Tamar",
        "category": "natureza",
        "lat": -3.8480,
        "lon": -32.4280,
        "duration_min": 60,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 95.0,
        "rating_avg": 4.8,
        "rating_count": 2800,
        "likes_count": 6200,
        "rank_posicao": 5,
        "description": "Palestras diárias noturnas gratuitas sobre a vida marinha e proteção das tartarugas marinhas.",
        "image_url": "https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80",
        "opening_time": "09:00",
        "closing_time": "22:00"
    },
    {
        "id": "mergulho_naufragio_porto",
        "city_slug": "noronha",
        "name": "Mergulho no Naufrágio do Porto de Santo Antônio",
        "category": "aventura",
        "lat": -3.8420,
        "lon": -32.4170,
        "duration_min": 150,
        "cost_level": 4,
        "kid_friendly": 0,
        "must_see": 1,
        "is_lunch": 0,
        "score": 98.0,
        "rating_avg": 4.9,
        "rating_count": 3200,
        "likes_count": 8100,
        "rank_posicao": 6,
        "description": "Mergulho com cilindro ou snorkel entre cardumes, arraias e tartarugas no navio grego naufragado na costa.",
        "image_url": "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "16:00"
    },
    {
        "id": "forte_do_boldro_sunset",
        "city_slug": "noronha",
        "name": "Mirante do Forte São Pedro do Boldró",
        "category": "cultura",
        "lat": -3.8475,
        "lon": -32.4350,
        "duration_min": 75,
        "cost_level": 1,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 96.0,
        "rating_avg": 4.9,
        "rating_count": 4500,
        "likes_count": 9700,
        "rank_posicao": 7,
        "description": "O entardecer mais aplaudido da ilha, com vista panorâmica do Morro Dois Irmãos e ruínas históricas.",
        "image_url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "opening_time": "16:00",
        "closing_time": "19:00"
    },
    {
        "id": "trilha_atalaia",
        "city_slug": "noronha",
        "name": "Trilha do Atalaia & Aquário Natural",
        "category": "aventura",
        "lat": -3.8450,
        "lon": -32.4080,
        "duration_min": 120,
        "cost_level": 2,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 0,
        "score": 95.5,
        "rating_avg": 4.8,
        "rating_count": 2900,
        "likes_count": 6700,
        "rank_posicao": 8,
        "description": "Flutuação controlada de 30 minutos em berçário marinho raso de corais repleto de tubarões-lixa filhotes.",
        "image_url": "https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=800&q=80",
        "opening_time": "08:00",
        "closing_time": "15:00"
    },
    {
        "id": "restaurante_varanda",
        "city_slug": "noronha",
        "name": "Restaurante Varanda (Chef Auricélio Romão)",
        "category": "gastronomia",
        "lat": -3.8495,
        "lon": -32.4260,
        "duration_min": 80,
        "cost_level": 4,
        "kid_friendly": 1,
        "must_see": 1,
        "is_lunch": 1,
        "score": 96.5,
        "rating_avg": 4.9,
        "rating_count": 3100,
        "likes_count": 6900,
        "rank_posicao": 9,
        "description": "Culinária sofisticada noronhense, consagrada pelo 'Peixe na Telha' e moquecas com leite de coco fresco.",
        "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80",
        "opening_time": "12:00",
        "closing_time": "23:00"
    },
    {
        "id": "cacimba_bistro",
        "city_slug": "noronha",
        "name": "Cacimba Bistrô",
        "category": "gastronomia",
        "lat": -3.8440,
        "lon": -32.4220,
        "duration_min": 80,
        "cost_level": 4,
        "kid_friendly": 0,
        "must_see": 1,
        "is_lunch": 1,
        "score": 95.0,
        "rating_avg": 4.8,
        "rating_count": 2600,
        "likes_count": 5800,
        "rank_posicao": 10,
        "description": "Bistrô charmoso no centro histórico da Vila dos Remédios, famoso pelos pastéis de lagosta e ambiente rústico-chique.",
        "image_url": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
        "opening_time": "12:00",
        "closing_time": "23:30"
    }
]

CITY_MAP = {
    "recife": RECIFE_PLACES,
    "porto_de_galinhas": PORTO_DE_GALINHAS_PLACES,
    "carneiros": CARNEIROS_PLACES,
    "noronha": NORONHA_PLACES,
}

def build_pack(output_path, city_slug="recife"):
    places = CITY_MAP.get(city_slug.lower())
    if not places:
        raise ValueError(f"Unknown city_slug: {city_slug}. Available: {list(CITY_MAP.keys())}")

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    if os.path.exists(output_path):
        os.remove(output_path)

    conn = sqlite3.connect(output_path)
    cur = conn.cursor()

    # 1. Metadata Table
    cur.execute("""
        CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT
        );
    """)

    cur.execute("INSERT INTO metadata VALUES ('city_slug', ?)", (city_slug,))
    cur.execute("INSERT INTO metadata VALUES ('version', '1.0.0')")
    cur.execute("INSERT INTO metadata VALUES ('created_at', ?)", (datetime.now(timezone.utc).isoformat(),))
    cur.execute("INSERT INTO metadata VALUES ('total_places', ?)", (str(len(places)),))

    # 2. Place Table
    cur.execute("""
        CREATE TABLE place (
            id TEXT PRIMARY KEY,
            city_slug TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            duration_min INTEGER NOT NULL,
            cost_level INTEGER NOT NULL,
            kid_friendly INTEGER NOT NULL,
            must_see INTEGER NOT NULL,
            is_lunch INTEGER NOT NULL,
            score REAL NOT NULL,
            rating_avg REAL NOT NULL,
            rating_count INTEGER NOT NULL,
            likes_count INTEGER NOT NULL,
            rank_posicao INTEGER NOT NULL,
            description TEXT,
            image_url TEXT,
            opening_time TEXT,
            closing_time TEXT
        );
    """)

    # Indexes
    cur.execute("CREATE INDEX idx_place_city ON place (city_slug);")
    cur.execute("CREATE INDEX idx_place_category ON place (category);")
    cur.execute("CREATE INDEX idx_place_rank ON place (rank_posicao);")

    # Insert Places
    for p in places:
        cur.execute("""
            INSERT INTO place (
                id, city_slug, name, category, lat, lon, duration_min, cost_level,
                kid_friendly, must_see, is_lunch, score, rating_avg, rating_count,
                likes_count, rank_posicao, description, image_url, opening_time, closing_time
            ) VALUES (
                :id, :city_slug, :name, :category, :lat, :lon, :duration_min, :cost_level,
                :kid_friendly, :must_see, :is_lunch, :score, :rating_avg, :rating_count,
                :likes_count, :rank_posicao, :description, :image_url, :opening_time, :closing_time
            )
        """, p)

    # 3. Distance Matrix Table (Precomputed Pairwise Distances & Travel Times)
    cur.execute("""
        CREATE TABLE matrix (
            from_id TEXT NOT NULL,
            to_id TEXT NOT NULL,
            distance_meters INTEGER NOT NULL,
            walk_seconds INTEGER NOT NULL,
            drive_seconds INTEGER NOT NULL,
            PRIMARY KEY (from_id, to_id)
        );
    """)

    pair_count = 0
    for p1 in places:
        for p2 in places:
            if p1["id"] == p2["id"]:
                dist = 0
                walk_sec = 0
                drive_sec = 0
            else:
                dist = haversine_meters(p1["lat"], p1["lon"], p2["lat"], p2["lon"])
                walk_sec, drive_sec = estimate_travel_times(dist)

            cur.execute("""
                INSERT INTO matrix (from_id, to_id, distance_meters, walk_seconds, drive_seconds)
                VALUES (?, ?, ?, ?, ?)
            """, (p1["id"], p2["id"], dist, walk_sec, drive_sec))
            pair_count += 1

    conn.commit()
    conn.close()

    file_size_kb = os.path.getsize(output_path) / 1024.0
    print(f"SUCCESS: Generated city pack for '{city_slug}' at {output_path}")
    print(f"Stats: {len(places)} places, {pair_count} matrix pairs, {file_size_kb:.2f} KB")

def main():
    parser = argparse.ArgumentParser(description="Generate One Tour offline city pack SQLite")
    parser.add_argument("--city", default="recife", help="City slug (default: recife)")
    parser.add_argument("--output", default=None, help="Output path (optional)")
    parser.add_argument("--all", action="store_true", help="Generate all Pernambuco polo packs")
    args = parser.parse_args()

    default_base_dir = "f:/One_tour/mobile/assets/packs"

    if args.all:
        for slug in CITY_MAP.keys():
            out_file = os.path.join(default_base_dir, f"pack_{slug}.sqlite")
            build_pack(out_file, slug)
    else:
        out_file = args.output or os.path.join(default_base_dir, f"pack_{args.city}.sqlite")
        build_pack(out_file, args.city)

if __name__ == "__main__":
    main()
