import SwiftUI

struct PetTip: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

struct PetTipsView: View {
    enum PetKind: String, CaseIterable { case dog = "강아지", cat = "고양이" }
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedKind: PetKind = .dog
    @State private var expandedTipIDs: Set<UUID> = []

    private let dogTips: [PetTip] = [
        PetTip(title: "산책 후 발바닥 확인", content: "발가락 사이에는 작은 돌이나 가시가 끼기 쉬워요. 여름의 뜨거운 바닥과 겨울 제설제도 자극이 될 수 있습니다. 산책 뒤 가볍게 닦고 붉어짐이나 절뚝거림이 없는지 살펴보세요."),
        PetTip(title: "식단은 천천히 바꾸기", content: "사료나 간식을 갑자기 바꾸면 소화가 불편할 수 있어요. 새 음식은 기존 음식에 조금씩 섞어 며칠에 걸쳐 바꿔 보세요. 구토나 설사가 반복되면 병원 상담이 필요할 수 있습니다."),
        PetTip(title: "물 마시는 양 살피기", content: "깨끗한 물을 언제든 마실 수 있도록 준비해 주세요. 날씨와 활동량에 따라 마시는 양은 달라질 수 있습니다. 갑작스러운 변화가 이어지면 기록해 두고 상담을 고려해 보세요."),
        PetTip(title: "양치 습관 만들기", content: "짧은 시간부터 시작해 입 주변을 만지는 데 익숙하게 해 주세요. 반려동물용 칫솔과 치약을 사용하고 사람용 치약은 피해야 합니다. 잇몸 출혈이나 심한 입 냄새가 보이면 전문가와 상의하세요."),
        PetTip(title: "간식은 적당히", content: "간식도 하루 섭취량에 포함해 생각하는 것이 좋아요. 작은 크기로 나누어 훈련 보상처럼 활용하면 부담을 줄일 수 있습니다. 새로운 간식 뒤 몸 상태가 달라지는지도 관찰해 주세요."),
        PetTip(title: "더운 날 산책 주의", content: "한낮의 아스팔트는 사람보다 강아지 발에 더 뜨거울 수 있어요. 그늘이 있는 시간에 짧게 산책하고 물을 준비해 주세요. 심하게 헐떡이거나 기운이 없으면 즉시 쉬게 하고 상담을 고려하세요."),
        PetTip(title: "발톱 길이 살피기", content: "발톱이 너무 길면 걷는 자세에 부담이 될 수 있습니다. 바닥에 닿는 소리와 발톱의 휘어짐을 가끔 확인해 주세요. 직접 자르기 어렵다면 미용실이나 병원의 도움을 받아도 좋아요."),
        PetTip(title: "귀 상태 관찰하기", content: "귀를 자주 긁거나 머리를 흔드는지 살펴보세요. 냄새, 붉어짐, 분비물이 함께 보이면 귀 안을 무리하게 청소하지 않는 것이 좋습니다. 변화가 지속되면 병원 상담이 필요할 수 있어요."),
        PetTip(title: "눈물 변화 기록", content: "눈 주변의 눈물과 눈곱은 날씨나 털 자극으로 달라질 수 있어요. 부드러운 거즈로 겉을 닦고 색과 양의 변화를 기록해 보세요. 충혈이나 통증이 의심되면 상담을 고려하세요."),
        PetTip(title: "편안한 휴식 공간", content: "강아지가 방해받지 않고 쉴 수 있는 자리를 마련해 주세요. 가족의 왕래가 너무 잦지 않은 곳이 안정감을 줄 수 있습니다. 잠자는 시간과 자세가 크게 달라지는지도 관찰해 보세요."),
        PetTip(title: "장난감 안전 점검", content: "장난감은 사용 전후 찢어진 부분이나 떨어지는 조각이 없는지 확인하세요. 강하게 물어뜯는 아이에게는 크기와 재질이 맞는 제품을 골라 주세요. 손상된 장난감은 바로 치워야 합니다."),
        PetTip(title: "진드기와 이물질 확인", content: "풀숲을 다녀온 뒤 털과 귀 주변, 발가락 사이를 살펴보세요. 작은 이물질은 빗질과 닦기로 확인할 수 있습니다. 피부에 붙은 것이 보이면 무리하게 제거하지 말고 상담을 받아 보세요."),
        PetTip(title: "체중 정기적으로 기록", content: "같은 시간대와 비슷한 조건에서 체중을 재면 변화를 보기 쉬워요. 성장기와 성견의 적정 체중은 다를 수 있습니다. 짧은 기간에 큰 변화가 있으면 기록과 함께 상담을 고려하세요."),
        PetTip(title: "생활 리듬 유지", content: "식사와 산책 시간을 어느 정도 일정하게 유지하면 예측 가능한 하루를 만들 수 있어요. 일정이 바뀔 때는 조금씩 적응할 시간을 주세요. 수면이나 식욕 변화도 함께 기록하면 도움이 됩니다."),
        PetTip(title: "낯선 장소는 천천히", content: "새로운 장소에서는 강아지가 주변 냄새와 소리를 먼저 탐색하게 해 주세요. 억지로 다가가게 하기보다 안전한 거리를 유지하는 것이 좋습니다. 긴장 신호가 보이면 익숙한 곳으로 돌아가 주세요."),
        PetTip(title: "차량 이동 안전하게", content: "차 안에서는 이동장이나 안전벨트용 하네스를 사용해 주세요. 창문을 크게 열어 머리를 내밀게 하는 행동은 피하는 것이 안전합니다. 장거리 이동 전에는 짧은 거리부터 연습해 보세요."),
        PetTip(title: "피부와 털 살피기", content: "빗질은 털 엉킴을 줄이고 피부 변화를 발견하는 데 도움이 됩니다. 붉은 반점이나 계속 긁는 부위가 있는지 확인해 주세요. 증상이 이어지면 병원 상담이 필요할 수 있어요."),
        PetTip(title: "사회화는 즐겁게", content: "사람과 다른 동물을 만나는 경험은 강아지의 속도에 맞춰 진행해 주세요. 짧고 긍정적인 만남을 반복하는 것이 부담을 줄일 수 있습니다. 불안해하면 거리를 늘리고 쉬게 해 주세요."),
        PetTip(title: "혼자 있는 시간 준비", content: "외출 전 충분한 휴식과 안전한 장난감을 준비해 주세요. 처음부터 긴 시간 혼자 두기보다 짧은 시간부터 연습하는 것이 좋습니다. 귀가 후에는 차분하게 인사해 주세요."),
        PetTip(title: "배변 상태 관찰", content: "배변 횟수와 형태는 평소 상태를 알아보는 데 도움이 됩니다. 하루 이틀의 작은 변화는 식사나 환경 때문일 수 있어요. 혈변이나 반복되는 설사처럼 걱정되는 변화는 상담을 고려하세요."),
        PetTip(title: "식욕 변화 메모", content: "평소 먹는 양과 식사 속도를 알아두면 변화를 빠르게 찾을 수 있어요. 간식 때문에 식사를 덜 할 수도 있으니 함께 기록해 보세요. 식욕 저하가 계속되면 병원 상담이 필요할 수 있습니다."),
        PetTip(title: "비 오는 날 털 말리기", content: "젖은 털을 오래 방치하면 피부가 불편할 수 있어요. 산책 후 수건으로 물기를 닦고 발가락 사이도 확인해 주세요. 완전히 말리는 동안 따뜻하고 편안하게 쉬게 해 주세요."),
        PetTip(title: "예방 일정 기록", content: "예방접종과 정기 검진 날짜를 캘린더에 기록해 두면 놓치기 쉬운 일정을 관리하기 좋아요. 강아지의 나이와 생활환경에 따라 필요한 일정은 다를 수 있습니다. 수의사와 계획을 세워 보세요."),
        PetTip(title: "칭찬은 바로 하기", content: "원하는 행동을 했을 때 짧고 일관된 칭찬을 바로 전달해 주세요. 간식뿐 아니라 목소리와 놀이도 좋은 보상이 될 수 있어요. 가족 모두 같은 기준을 사용하면 배우기 쉽습니다."),
        PetTip(title: "집안 위험 물건 치우기", content: "작은 장난감, 전선, 세제와 음식물은 강아지가 닿지 않는 곳에 보관하세요. 새로운 공간을 사용하기 전 바닥과 낮은 선반을 확인해 주세요. 무언가 삼킨 것 같다면 바로 상담을 받아야 합니다."),
        PetTip(title: "산책 시간은 체력에 맞게", content: "나이와 체력에 따라 산책 시간과 속도를 조절해 주세요. 짧은 산책을 여러 번 하는 것이 편한 아이도 있습니다. 산책 후 회복하는 데 오래 걸리면 다음 활동량을 줄여 보세요."),
        PetTip(title: "꼬리와 귀로 기분 읽기", content: "꼬리, 귀, 몸의 자세는 강아지의 감정을 살피는 단서가 됩니다. 몸을 굳히거나 피하려는 모습은 긴장 신호일 수 있어요. 신호를 존중하고 충분한 거리를 주세요."),
        PetTip(title: "새 간식은 소량부터", content: "새로운 간식은 아주 작은 양으로 시작해 몸 상태를 관찰하세요. 여러 가지를 한꺼번에 바꾸면 어떤 음식이 맞지 않는지 알기 어렵습니다. 이상 반응이 보이면 중단하고 상담을 고려하세요."),
        PetTip(title: "수면 환경 살피기", content: "강아지는 하루 중 많은 시간을 잠으로 보내므로 조용한 휴식이 중요해요. 빛과 소음이 적은 자리를 마련하고 자는 아이를 자주 깨우지 마세요. 수면 패턴이 갑자기 바뀌면 기록해 두세요."),
        PetTip(title: "작은 변화도 기록하기", content: "식사, 산책, 배변과 기분을 짧게 적어두면 평소 상태를 파악하기 좋아요. 사진과 함께 기록하면 변화가 더 잘 보일 수 있습니다. 이상이 반복되면 기록을 가지고 전문가와 상담해 보세요.")
    ]

    private let catTips: [PetTip] = [
        PetTip(title: "음수량 살펴보기", content: "고양이는 물을 많이 마시지 않는 경우가 있어 음수량을 관찰하는 것이 좋아요. 여러 장소에 깨끗한 물을 두거나 흐르는 물을 선호하는지 살펴보세요. 소변 변화가 함께 나타나면 상담을 고려하세요."),
        PetTip(title: "화장실 변화 확인", content: "화장실 횟수와 양, 모래 상태는 고양이의 평소 컨디션을 알아보는 단서예요. 갑자기 자주 가거나 오래 머무는 변화가 반복되면 기록해 주세요. 소변을 보기 어려워 보이면 병원 상담이 필요할 수 있습니다."),
        PetTip(title: "숨는 행동 이해하기", content: "고양이는 낯선 소리나 손님이 있을 때 숨으며 안정을 찾을 수 있어요. 숨을 수 있는 조용한 공간을 마련해 주고 억지로 꺼내지 마세요. 평소와 다른 숨기 행동이 오래가면 상태를 살펴보세요."),
        PetTip(title: "헤어볼과 빗질", content: "정기적인 빗질은 빠진 털을 줄이고 피부를 확인하는 데 도움이 됩니다. 털 길이와 고양이의 반응에 맞춰 짧게 진행해 주세요. 구토가 잦거나 식욕 변화가 있으면 상담을 고려하세요."),
        PetTip(title: "높은 곳의 안정감", content: "높은 곳은 고양이가 주변을 관찰하며 쉬기 좋은 장소가 될 수 있어요. 흔들리지 않는 캣타워나 선반을 준비하고 추락 위험을 점검해 주세요. 창문과 베란다에는 안전장치를 사용하세요."),
        PetTip(title: "화장실은 깨끗하게", content: "고양이는 화장실 청결에 민감할 수 있어 자주 정리해 주세요. 조용하고 쉽게 접근할 수 있는 위치가 좋습니다. 갑자기 화장실을 피하면 환경 변화나 건강 문제를 살펴보세요."),
        PetTip(title: "스크래처 준비하기", content: "스크래칭은 발톱 관리와 스트레스 해소에 도움이 되는 자연스러운 행동이에요. 고양이가 자주 지나는 곳에 세로형과 가로형을 시도해 보세요. 손상된 스크래처는 교체해 주세요."),
        PetTip(title: "사료는 천천히 바꾸기", content: "고양이도 갑작스러운 식단 변경에 예민할 수 있습니다. 새 사료는 기존 사료와 섞어 조금씩 비율을 바꿔 보세요. 구토나 설사가 반복되면 병원 상담이 필요할 수 있어요."),
        PetTip(title: "창문 안전 점검", content: "방충망만으로는 고양이의 추락을 막기 어려울 수 있어요. 창문과 베란다의 잠금 상태와 안전망을 정기적으로 확인하세요. 높은 곳에 올라가는 습관이 있는 아이일수록 예방이 중요합니다."),
        PetTip(title: "혼자 쉴 자리 만들기", content: "고양이는 사람의 손길을 피하고 혼자 쉬고 싶을 때가 있어요. 박스나 숨숨집처럼 드나들 수 있는 공간을 준비해 주세요. 그곳에서는 억지로 꺼내지 않는 것이 좋습니다."),
        PetTip(title: "귀와 피부 관찰", content: "귀를 자주 긁거나 냄새가 나는지, 피부에 붉은 부분이 있는지 살펴보세요. 면봉을 깊이 넣거나 강한 세정제를 임의로 사용하지 않는 것이 안전합니다. 변화가 이어지면 상담을 고려하세요."),
        PetTip(title: "눈곱과 눈물 확인", content: "눈곱의 양과 색, 눈을 찡그리는지 여부를 평소와 비교해 보세요. 부드러운 거즈로 겉을 닦되 눈을 세게 문지르지 마세요. 충혈이나 통증이 의심되면 병원 상담이 필요할 수 있어요."),
        PetTip(title: "식사량 기록하기", content: "고양이는 아픈 티를 늦게 내는 편이라 평소 식사량을 알아두면 도움이 됩니다. 사료를 남기는 양과 식사 속도를 함께 기록해 보세요. 갑작스러운 식욕 저하는 상담을 고려할 신호일 수 있습니다."),
        PetTip(title: "짧고 자주 놀기", content: "고양이는 짧은 사냥 놀이를 여러 번 하는 것을 좋아할 수 있어요. 장난감으로 움직임을 유도하고 놀이 후에는 휴식 시간을 주세요. 끈이나 작은 부품은 보호자가 지켜볼 때만 사용하세요."),
        PetTip(title: "위험한 식물 확인", content: "실내 식물 중에는 고양이에게 자극이 될 수 있는 종류가 있어요. 새 식물을 들이기 전 안전한 종류인지 확인해 주세요. 잎을 먹은 뒤 구토나 침 흘림이 보이면 상담을 고려하세요."),
        PetTip(title: "털 엉킴 예방", content: "털이 긴 고양이는 엉킴이 생기기 쉬워 짧은 빗질을 자주 해주는 것이 좋아요. 엉킨 털을 억지로 당기면 피부가 아플 수 있습니다. 심한 엉킴은 전문가의 도움을 받아 주세요."),
        PetTip(title: "모래 취향 관찰", content: "고양이마다 선호하는 모래의 종류와 향이 다를 수 있어요. 모래를 바꿀 때는 기존 모래와 섞어 천천히 적응시켜 주세요. 화장실 사용을 꺼리면 위치와 청결도 함께 확인하세요."),
        PetTip(title: "갑작스러운 공격성", content: "갑자기 물거나 할퀴는 행동은 놀람, 스트레스 또는 불편함 때문일 수 있어요. 혼내기보다 자극을 줄이고 쉴 공간을 제공해 주세요. 변화가 반복되면 전문가와 상담을 고려하세요."),
        PetTip(title: "이동장 익숙해지기", content: "이동장을 병원 갈 때만 꺼내면 고양이가 긴장할 수 있어요. 평소 문을 열어 두고 담요나 간식을 넣어 편안한 장소로 익숙하게 해 보세요. 억지로 넣기보다 짧게 연습하세요."),
        PetTip(title: "체중 변화 기록", content: "정기적으로 체중을 재면 고양이의 변화를 일찍 알아차리는 데 도움이 됩니다. 같은 시간과 비슷한 조건을 유지하면 비교하기 쉬워요. 짧은 기간에 큰 변화가 있으면 상담을 고려하세요."),
        PetTip(title: "잠자는 모습 살피기", content: "고양이는 원래 잠이 많지만 평소와 다른 자세와 움직임은 기록해 둘 만해요. 편안하게 쉬는 공간을 방해하지 말고 관찰해 주세요. 기운이 크게 떨어진 모습이 지속되면 상담이 필요할 수 있습니다."),
        PetTip(title: "반복되는 구토 관찰", content: "가끔 털을 토할 수 있지만 반복되면 다른 원인이 있을 수 있어요. 횟수와 내용, 식사와의 관계를 기록해 보세요. 반복되거나 컨디션 저하가 함께 있으면 병원 상담을 고려하세요."),
        PetTip(title: "실내 활동 늘리기", content: "실내 생활 고양이도 놀이와 탐색 시간이 필요해요. 창가 자리, 터널, 장난감으로 환경을 다양하게 만들어 주세요. 새로운 물건은 고양이가 스스로 다가갈 시간을 주세요."),
        PetTip(title: "물그릇 위치 나누기", content: "사료 옆 물을 싫어하는 고양이도 있어 물그릇 위치를 나누어 시도해 볼 수 있어요. 매일 깨끗한 물로 갈아주고 그릇의 재질과 높이도 관찰하세요. 마시는 양의 변화는 기록해 두면 좋습니다."),
        PetTip(title: "환경 변화는 천천히", content: "가구나 화장실 위치를 한 번에 바꾸면 고양이가 스트레스를 받을 수 있어요. 필요한 변화는 조금씩 진행하고 익숙한 물건을 함께 두세요. 숨기나 식욕 변화가 있는지 살펴보세요."),
        PetTip(title: "발톱 관리 준비", content: "발을 만지는 연습을 평소에 짧게 하면 발톱 관리가 쉬워질 수 있어요. 고양이용 발톱깎이를 사용하고 무리하게 진행하지 마세요. 어렵다면 미용 전문가나 병원에 도움을 요청하세요."),
        PetTip(title: "예방 일정 기록", content: "예방접종과 건강검진 일정을 캘린더에 기록해 두세요. 고양이의 나이와 생활환경에 따라 필요한 관리가 다를 수 있습니다. 정기 상담으로 아이에게 맞는 계획을 세워 보세요."),
        PetTip(title: "손님을 위한 숨숨집", content: "낯선 사람이 오면 숨을 수 있는 공간이 고양이에게 도움이 될 수 있어요. 손님에게 억지로 꺼내거나 만지지 말아 달라고 알려 주세요. 스스로 나왔을 때 조용히 반응해 주세요."),
        PetTip(title: "배변 변화 메모", content: "배변 횟수와 형태를 평소와 비교해 보세요. 사료나 모래, 환경 변화도 함께 적으면 원인을 살피는 데 도움이 됩니다. 변화가 반복되거나 불편해 보이면 병원 상담을 고려하세요."),
        PetTip(title: "작은 변화도 존중하기", content: "고양이는 행동으로 불편함을 표현하는 경우가 많아요. 식사, 놀이, 그루밍과 숨는 시간의 변화를 가볍게 기록해 보세요. 평소와 다른 상태가 이어지면 전문가와 상의하는 것이 좋습니다.")
    ]

    private var todaysTips: [PetTip] {
        let source = selectedKind == .dog ? dogTips : catTips
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return (0..<5).map { source[(day - 1 + $0) % source.count] }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("펫상식").font(.largeTitle.bold())
                    Text("오늘 알아두면 좋은 반려동물 기본상식").font(.subheadline).foregroundStyle(.secondary)
                    Text(Date.now, format: .dateTime.year().month().day()).font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    ForEach(PetKind.allCases, id: \.self) { kind in
                        Button {
                            withAnimation { selectedKind = kind; expandedTipIDs.removeAll() }
                        } label: {
                            Label(kind.rawValue, systemImage: kind == .dog ? "pawprint.fill" : "cat.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(selectedKind == kind ? .white : themeManager.theme.palette.text)
                                .background(selectedKind == kind ? themeManager.theme.palette.accent : Color(.tertiarySystemGroupedBackground), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                tipSection(title: selectedKind == .dog ? "오늘의 강아지 상식" : "오늘의 고양이 상식", tips: todaysTips)
            }
            .padding(16)
        }
        .background(CareBackground())
        .navigationTitle("펫상식")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.theme.palette.accent)
    }

    private func tipSection(title: String, tips: [PetTip]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: selectedKind == .dog ? "pawprint.fill" : "cat.fill").font(.headline)
            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                Button {
                    withAnimation(.easeInOut) {
                        if expandedTipIDs.contains(tip.id) { expandedTipIDs.remove(tip.id) } else { expandedTipIDs.insert(tip.id) }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)").font(.caption.weight(.bold)).foregroundStyle(themeManager.theme.palette.accent).frame(width: 22, height: 22).background(themeManager.theme.palette.accent.opacity(0.12), in: Circle())
                            Text(tip.title).font(.subheadline.weight(.semibold)).foregroundStyle(themeManager.theme.palette.text).multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: expandedTipIDs.contains(tip.id) ? "chevron.up" : "chevron.down").font(.caption).foregroundStyle(.secondary)
                        }
                        if expandedTipIDs.contains(tip.id) {
                            Text(tip.content).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(themeManager.theme.palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .careCard()
    }
}
